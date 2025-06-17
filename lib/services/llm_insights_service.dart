import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../database/session_database.dart';

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

      final prompt = '''
You are an expert climbing strength coach trained in Lattice Training methodology. Analyze this hangboard/finger strength training data and provide personalized recommendations following evidence-based climbing training principles:

Training Analysis:
${jsonEncode(analysisData)}

${specificGoal != null ? 'Specific Goal: $specificGoal' : ''}

Apply Lattice Training principles:
- Periodization (Base → Strength → Power → Performance phases)
- Load management and progressive overload
- Finger strength development (max hangs, repeaters, density hangs)
- Recovery protocols and CNS management
- Assessment-driven training adjustments
- Sport-specific adaptations for climbing

Provide exactly 4-6 comprehensive recommendations in JSON format:
[
  {
    "title": "Clear recommendation title",
    "description": "Detailed explanation with climbing-specific advice and Lattice methodology",
    "priority": "high/medium/low",
    "category": "finger_strength/load_management/periodization/recovery/assessment",
    "actionItems": ["Specific climbing training action 1", "Specific climbing training action 2"]
  }
]

Focus on:
- Finger strength progression (max hangs, repeaters, edge sizes)
- Training load and volume management
- Periodization and training phase recommendations
- Recovery protocols (sleep, nutrition, deload weeks)
- Injury prevention for finger/shoulder health
- Assessment benchmarks and testing protocols
- Training specificity for climbing performance

Use climbing-specific terminology and reference Lattice Training concepts where appropriate.
Respond with ONLY the JSON array, no other text.
''';

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

      return TrainingInsights(
        recommendations: recommendations,
        analysisData: analysisData,
        generatedAt: DateTime.now(),
      );
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
      throw Exception('Gemini API key not configured');
    }

    try {
      final recentData = _prepareRecentAnalysis(recentSessions, weightUnit);

      final prompt = '''
You are a climbing strength coach using Lattice Training methodology. Based on this recent hangboard/finger strength training data, provide 3-4 concise, actionable tips following evidence-based climbing training principles:

Recent Training Data:
${jsonEncode(recentData)}

Apply Lattice Training insights for:
- Finger strength progression and load management
- Recovery optimization between sessions
- Training intensity and volume adjustments
- Injury prevention protocols
- Performance benchmarking

Focus on immediate improvements for next hangboard session, climbing-specific recovery recommendations, and motivation.

Use climbing terminology: max hangs, repeaters, edge sizes, crimp/open hand positions, recruitment protocols, CNS recovery.

Respond with a JSON array of tip strings only:
["climbing-specific tip 1", "climbing-specific tip 2", "climbing-specific tip 3", "climbing-specific tip 4"]
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null) {
        throw Exception('No response from AI model');
      }

      final cleanedResponse = _extractJsonFromResponse(responseText);
      final tips = (jsonDecode(cleanedResponse) as List<dynamic>)
          .map((tip) => tip.toString())
          .toList();

      return tips;
    } catch (e) {
      debugPrint('Error generating quick tips: $e');
      throw Exception('Failed to generate quick tips: $e');
    }
  }

  /// Analyzes performance trends and patterns
  static Future<PerformanceAnalysis> analyzePerformance({
    required List<Session> sessions,
    required String weightUnit,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Gemini API key not configured');
    }

    try {
      final performanceData = _preparePerformanceAnalysis(sessions, weightUnit);

      final prompt = '''
You are a climbing strength coach using Lattice Training methodology. Analyze this hangboard/finger strength training performance data using evidence-based climbing training principles:

Performance Data:
${jsonEncode(performanceData)}

Apply Lattice Training assessment protocols:
- Finger strength benchmarks (20mm edge, bodyweight percentages)
- Load progression patterns and periodization analysis
- Training volume and recovery balance assessment
- CNS fatigue and adaptation indicators
- Climbing-specific strength development patterns

Provide analysis in this exact JSON format:
{
  "strengthTrend": "improving/declining/stable/plateau",
  "consistencyRating": "excellent/good/needs_improvement/inconsistent",
  "weakAreas": ["specific climbing weakness 1", "specific climbing weakness 2"],
  "strongSuits": ["climbing strength 1", "climbing strength 2"],
  "nextGoals": ["climbing-specific goal 1", "climbing-specific goal 2"],
  "trainingPhase": "base_building/strength_phase/power_phase/performance_phase/deload_needed"
}

Use climbing-specific terminology and Lattice Training concepts for assessment.
Respond with ONLY the JSON object, no other text.
''';

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
      throw Exception('Failed to analyze performance: $e');
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

/// Data class for training insights
class TrainingInsights {
  final List<TrainingRecommendation> recommendations;
  final Map<String, dynamic> analysisData;
  final DateTime generatedAt;

  TrainingInsights({
    required this.recommendations,
    required this.analysisData,
    required this.generatedAt,
  });
}

/// Data class for individual training recommendations
class TrainingRecommendation {
  final String title;
  final String description;
  final String priority; // high, medium, low
  final String category; // strength, technique, recovery, etc.
  final List<String> actionItems;

  TrainingRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.actionItems,
  });

  factory TrainingRecommendation.fromJson(Map<String, dynamic> json) {
    return TrainingRecommendation(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'medium',
      category: json['category'] ?? 'general',
      actionItems: (json['actionItems'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
    );
  }

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFE57373); // Red
      case 'medium':
        return const Color(0xFFFFB74D); // Orange
      case 'low':
        return const Color(0xFF81C784); // Green
      default:
        return const Color(0xFF90A4AE); // Grey
    }
  }

  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'finger_strength':
        return const Color(0xFF42A5F5); // Blue
      case 'load_management':
        return const Color(0xFF66BB6A); // Green
      case 'periodization':
        return const Color(0xFFFF9800); // Orange
      case 'recovery':
        return const Color(0xFFAB47BC); // Purple
      case 'assessment':
        return const Color(0xFF26A69A); // Teal
      case 'consistency':
        return const Color(0xFFFF7043); // Deep Orange
      case 'strength':
        return const Color(0xFF42A5F5); // Blue (fallback)
      case 'technique':
        return const Color(0xFF66BB6A); // Green (fallback)
      case 'goal_setting':
        return const Color(0xFF26A69A); // Teal (fallback)
      default:
        return const Color(0xFF78909C); // Blue Grey
    }
  }
}

/// Data class for performance analysis
class PerformanceAnalysis {
  final String strengthTrend;
  final String consistencyRating;
  final List<String> weakAreas;
  final List<String> strongSuits;
  final List<String> nextGoals;
  final String trainingPhase;

  PerformanceAnalysis({
    required this.strengthTrend,
    required this.consistencyRating,
    required this.weakAreas,
    required this.strongSuits,
    required this.nextGoals,
    required this.trainingPhase,
  });

  factory PerformanceAnalysis.fromJson(Map<String, dynamic> json) {
    return PerformanceAnalysis(
      strengthTrend: json['strengthTrend'] ?? 'stable',
      consistencyRating: json['consistencyRating'] ?? 'good',
      weakAreas: (json['weakAreas'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      strongSuits: (json['strongSuits'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      nextGoals: (json['nextGoals'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      trainingPhase: json['trainingPhase'] ?? 'intermediate',
    );
  }
}
