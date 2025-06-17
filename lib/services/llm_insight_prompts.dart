import 'dart:convert';
import 'package:flutter/material.dart';

/// Helper class to build all LLM prompts used by `LLMInsightsService`.
///
/// Keeping the prompt templates in a dedicated file avoids cluttering the
/// service implementation and makes prompt iteration easier.
class LLMInsightPrompts {
  /// Returns the prompt used by `LLMInsightsService.generateInsights()`.
  ///
  /// [analysisData] – output of `_prepareTrainingAnalysis()`.
  /// [specificGoal] – optional goal provided by the user.
  static String insightsPrompt({
    required Map<String, dynamic> analysisData,
    String? specificGoal,
  }) {
    return '''
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
  }

  /// Returns the prompt used by `LLMInsightsService.generateQuickTips()`.
  ///
  /// [recentData] – output of `_prepareRecentAnalysis()`.
  static String quickTipsPrompt({
    required Map<String, dynamic> recentData,
  }) {
    return '''
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
  }

  /// Returns the prompt used by `LLMInsightsService.analyzePerformance()`.
  ///
  /// [performanceData] – output of `_preparePerformanceAnalysis()`.
  static String performanceAnalysisPrompt({
    required Map<String, dynamic> performanceData,
  }) {
    return '''
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
  }

  // ---------------------------------------------------------------------
  // Data classes representing the structured responses expected from LLM.
  // Moving them here keeps everything related to prompt format & parsing in
  // one place for easier maintenance.
  // ---------------------------------------------------------------------

  /// Wrapper for a list of recommendations alongside their originating
  /// analysis data and timestamp.
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

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'priority': priority,
        'category': category,
        'actionItems': actionItems,
      };

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
      case 'strength':
        return const Color(0xFF42A5F5); // Blue
      case 'technique':
        return const Color(0xFF66BB6A); // Green
      case 'recovery':
        return const Color(0xFFAB47BC); // Purple
      case 'consistency':
        return const Color(0xFFFF7043); // Deep Orange
      case 'goal_setting':
        return const Color(0xFF26A69A); // Teal
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
