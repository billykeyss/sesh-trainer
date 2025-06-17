import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../database/session_database.dart';
import 'llm_insight_prompts.dart';

class LLMInsightsService {
  // Get API key from environment variables
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static GenerativeModel? _model;

  static GenerativeModel get model {
    _model ??= GenerativeModel(
      model: dotenv.env['GEMINI_MODEL'] ??
          'gemini-2.0-flash-exp', // Latest Gemini 2.0 Flash - cheaper and faster
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: double.tryParse(dotenv.env['TEMPERATURE'] ?? '0.7') ?? 0.7,
        topK: int.tryParse(dotenv.env['TOP_K'] ?? '40') ?? 40,
        topP: double.tryParse(dotenv.env['TOP_P'] ?? '0.95') ?? 0.95,
        maxOutputTokens:
            int.tryParse(dotenv.env['MAX_TOKENS'] ?? '1000') ?? 1000,
      ),
    );
    return _model!;
  }

  /// Generates comprehensive training insights and recommendations
  static Future<TrainingInsights> generateInsights({
    required List<Session> sessions,
    required String weightUnit,
    String? specificGoal,
  }) async {
    // Check if API key is configured
    if (_apiKey.isEmpty) {
      throw Exception('Gemini API key not configured');
    }

    try {
      // Prepare training data summary for AI analysis
      final analysisData = _prepareTrainingAnalysis(sessions, weightUnit);

      // Build the prompt using the centralized prompt builder
      final prompt = LLMInsightPrompts.insightsPrompt(
        analysisData: analysisData,
        specificGoal: specificGoal,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null) {
        throw Exception('No response from AI model');
      }

      // Clean the response to extract JSON
      final cleanedResponse = _extractJsonFromResponse(responseText);
      final recommendationsJson = jsonDecode(cleanedResponse) as List<dynamic>;

      final recommendations = recommendationsJson
          .map((rec) => TrainingRecommendation.fromJson(rec))
          .toList();

      final insights = TrainingInsights(
        recommendations: recommendations,
        analysisData: analysisData,
        generatedAt: DateTime.now(),
      );

      // Persist to database
      final db = SessionDatabase();
      await db.clearInsights(); // keep only latest
      await db.insertInsight(AiInsightsCompanion(
        recommendationsJson:
            Value(jsonEncode(recommendations.map((e) => e.toJson()).toList())),
        analysisDataJson: Value(jsonEncode(analysisData)),
        generatedAt: Value(insights.generatedAt),
      ));

      return insights;
    } catch (e) {
      debugPrint('Error generating AI insights: $e');
      throw Exception('Failed to generate AI insights: $e');
    }
  }

  /// Generates quick tips based on recent performance
  static Future<List<String>> generateQuickTips({
    required List<Session> recentSessions,
    required String weightUnit,
  }) async {
    // Check if API key is configured
    if (_apiKey.isEmpty) {
      debugPrint('Gemini API key not configured.');
      throw Exception('API Key empty cannot generate insights');
    }

    try {
      final recentData = _prepareRecentAnalysis(recentSessions, weightUnit);

      // Build the prompt using the centralized prompt builder
      final prompt = LLMInsightPrompts.quickTipsPrompt(
        recentData: recentData,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null) {
        throw Exception('No response from AI model');
      }

      final cleanedResponse = _extractJsonFromResponse(responseText);
      final tips = (jsonDecode(cleanedResponse) as List<dynamic>)
          .map((tip) => tip.toString())
          .toList();

      // Persist to DB
      final db = SessionDatabase();
      await db.clearQuickTips();
      await db.insertQuickTip(QuickTipsCompanion(
        tipsJson: Value(jsonEncode(tips)),
        generatedAt: Value(DateTime.now()),
      ));

      return tips;
    } catch (e) {
      debugPrint('Error generating quick tips: $e');
      throw Exception('Error generating quick tips');
    }
  }

  /// Analyzes performance trends and patterns
  static Future<PerformanceAnalysis> analyzePerformance({
    required List<Session> sessions,
    required String weightUnit,
  }) async {
    try {
      final performanceData = _preparePerformanceAnalysis(sessions, weightUnit);

      // Build the prompt using the centralized prompt builder
      final prompt = LLMInsightPrompts.performanceAnalysisPrompt(
        performanceData: performanceData,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null) {
        throw Exception('No response from AI model');
      }

      final cleanedResponse = _extractJsonFromResponse(responseText);
      final analysis = jsonDecode(cleanedResponse) as Map<String, dynamic>;

      return PerformanceAnalysis.fromJson(analysis);
    } catch (e) {
      debugPrint('Error analyzing performance: $e');
      throw Exception('Error analyzing performance');
    }
  }

  /// Extracts JSON from AI response, handling cases where AI adds extra text
  static String _extractJsonFromResponse(String response) {
    // Remove markdown code blocks if present
    String cleaned = response.replaceAll('```json', '').replaceAll('```', '');

    // Find the first [ or { and last ] or }
    int start = -1;
    int end = -1;

    for (int i = 0; i < cleaned.length; i++) {
      if (cleaned[i] == '[' || cleaned[i] == '{') {
        start = i;
        break;
      }
    }

    for (int i = cleaned.length - 1; i >= 0; i--) {
      if (cleaned[i] == ']' || cleaned[i] == '}') {
        end = i + 1;
        break;
      }
    }

    if (start != -1 && end != -1 && start < end) {
      return cleaned.substring(start, end);
    }

    return cleaned.trim();
  }

  /// Prepares comprehensive training data for AI analysis
  static Map<String, dynamic> _prepareTrainingAnalysis(
      List<Session> sessions, String weightUnit) {
    if (sessions.isEmpty) return {};

    // Sort sessions by date
    final sortedSessions = sessions.toList()
      ..sort((a, b) => a.sessionTime.compareTo(b.sessionTime));

    // Calculate key metrics
    final maxWeights = <double>[];
    final durations = <int>[];
    final sessionTypes = <String>[];

    for (final session in sortedSessions) {
      // Extract max weight from graph data
      try {
        final graphData = jsonDecode(session.graphData) as List<dynamic>;
        if (graphData.isNotEmpty) {
          final weights =
              graphData.map((point) => (point['y'] as num).toDouble()).toList();
          maxWeights.add(weights.reduce((a, b) => a > b ? a : b));
        }
      } catch (e) {
        debugPrint('Error parsing graph data: $e');
      }

      durations.add(session.elapsedTimeMs);

      // Determine session type from data field
      try {
        final data = jsonDecode(session.data);
        if (data['type'] == 'circuit_training') {
          sessionTypes.add('Circuit Training');
        } else {
          sessionTypes.add('Regular Training');
        }
      } catch (e) {
        sessionTypes.add('Regular Training');
      }
    }

    final now = DateTime.now();
    final recentSessions = sortedSessions
        .where((s) => now.difference(s.sessionTime).inDays <= 30)
        .toList();

    return {
      'totalSessions': sessions.length,
      'dateRange': {
        'start': sortedSessions.first.sessionTime.toIso8601String(),
        'end': sortedSessions.last.sessionTime.toIso8601String(),
      },
      'weightUnit': weightUnit,
      'maxWeights': maxWeights,
      'averageMaxWeight': maxWeights.isNotEmpty
          ? maxWeights.reduce((a, b) => a + b) / maxWeights.length
          : 0,
      'personalBest': maxWeights.isNotEmpty
          ? maxWeights.reduce((a, b) => a > b ? a : b)
          : 0,
      'averageDuration': durations.isNotEmpty
          ? durations.reduce((a, b) => a + b) /
              durations.length /
              60000 // Convert to minutes
          : 0,
      'sessionTypes': sessionTypes,
      'recentSessionsCount': recentSessions.length,
      'progressTrend': _calculateProgressTrend(maxWeights),
      'consistency': _calculateConsistency(sortedSessions),
    };
  }

  /// Prepares recent session data for quick analysis
  static Map<String, dynamic> _prepareRecentAnalysis(
      List<Session> sessions, String weightUnit) {
    final recentSessions = sessions
        .where((s) => DateTime.now().difference(s.sessionTime).inDays <= 7)
        .toList();

    return _prepareTrainingAnalysis(recentSessions, weightUnit);
  }

  /// Prepares performance-specific data for trend analysis
  static Map<String, dynamic> _preparePerformanceAnalysis(
      List<Session> sessions, String weightUnit) {
    final analysis = _prepareTrainingAnalysis(sessions, weightUnit);

    // Add performance-specific metrics
    final sortedSessions = sessions.toList()
      ..sort((a, b) => a.sessionTime.compareTo(b.sessionTime));

    // Calculate week-over-week improvements
    final weeklyAverages = <double>[];
    final now = DateTime.now();

    for (int week = 4; week >= 0; week--) {
      final weekStart = now.subtract(Duration(days: (week + 1) * 7));
      final weekEnd = now.subtract(Duration(days: week * 7));

      final weekSessions = sortedSessions.where((s) =>
          s.sessionTime.isAfter(weekStart) && s.sessionTime.isBefore(weekEnd));

      if (weekSessions.isNotEmpty) {
        final weekMaxes = weekSessions.map((s) {
          try {
            final graphData = jsonDecode(s.graphData) as List<dynamic>;
            if (graphData.isNotEmpty) {
              final weights = graphData
                  .map((point) => (point['y'] as num).toDouble())
                  .toList();
              return weights.reduce((a, b) => a > b ? a : b);
            }
          } catch (e) {
            debugPrint('Error parsing graph data: $e');
          }
          return 0.0;
        }).toList();

        if (weekMaxes.isNotEmpty) {
          weeklyAverages
              .add(weekMaxes.reduce((a, b) => a + b) / weekMaxes.length);
        }
      }
    }

    analysis['weeklyAverages'] = weeklyAverages;
    return analysis;
  }

  /// Calculates progress trend from max weights
  static String _calculateProgressTrend(List<double> maxWeights) {
    if (maxWeights.length < 3) return 'insufficient_data';

    final recent = maxWeights.skip(maxWeights.length - 5).toList();
    final earlier = maxWeights.take(maxWeights.length - 5).toList();

    if (earlier.isEmpty) return 'insufficient_data';

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final earlierAvg = earlier.reduce((a, b) => a + b) / earlier.length;

    final improvement = ((recentAvg - earlierAvg) / earlierAvg * 100);

    if (improvement > 5) return 'strong_improvement';
    if (improvement > 0) return 'slight_improvement';
    if (improvement > -5) return 'stable';
    return 'declining';
  }

  /// Calculates training consistency
  static double _calculateConsistency(List<Session> sessions) {
    if (sessions.length < 2) return 0;

    final daysBetweenSessions = <int>[];
    for (int i = 1; i < sessions.length; i++) {
      final gap = sessions[i]
          .sessionTime
          .difference(sessions[i - 1].sessionTime)
          .inDays;
      daysBetweenSessions.add(gap);
    }

    if (daysBetweenSessions.isEmpty) return 0;

    final averageGap = daysBetweenSessions.reduce((a, b) => a + b) /
        daysBetweenSessions.length;

    // Calculate consistency score based on regularity (ideal gap is 1-3 days)
    if (averageGap <= 3) return 100;
    if (averageGap <= 7) return 80;
    if (averageGap <= 14) return 60;
    return 40;
  }
}
