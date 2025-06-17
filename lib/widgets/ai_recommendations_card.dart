import 'package:flutter/material.dart';
import '../services/llm_insights_service.dart';
import '../services/llm_insight_prompts.dart';
import '../database/session_database.dart';
import 'dart:convert';

class AIRecommendationsCard extends StatefulWidget {
  final List<Session> sessions;
  final String weightUnit;
  final String? specificGoal;

  const AIRecommendationsCard({
    Key? key,
    required this.sessions,
    required this.weightUnit,
    this.specificGoal,
  }) : super(key: key);

  @override
  _AIRecommendationsCardState createState() => _AIRecommendationsCardState();
}

class _AIRecommendationsCardState extends State<AIRecommendationsCard> {
  TrainingInsights? insights;
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadCachedInsights();
  }

  Future<void> _loadCachedInsights() async {
    final db = SessionDatabase();
    final cached = await db.getLatestInsight();
    if (cached != null) {
      setState(() {
        insights = TrainingInsights(
          recommendations: (jsonDecode(cached.recommendationsJson)
                  as List<dynamic>)
              .map((e) =>
                  TrainingRecommendation.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
          analysisData:
              jsonDecode(cached.analysisDataJson) as Map<String, dynamic>,
          generatedAt: cached.generatedAt,
        );
      });
    }
  }

  Future<void> _generateInsights() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final newInsights = await LLMInsightsService.generateInsights(
        sessions: widget.sessions,
        weightUnit: widget.weightUnit,
        specificGoal: widget.specificGoal,
      );

      setState(() {
        insights = newInsights;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withOpacity(0.2),
                        Colors.blue.withOpacity(0.1)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Training Coach',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Personalized recommendations based on your training data',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLoading)
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _generateInsights,
                    tooltip: 'Refresh recommendations',
                  ),
              ],
            ),
            SizedBox(height: 20),

            // Content
            if (isLoading)
              _buildLoadingState()
            else if (error != null && insights == null)
              _buildErrorState()
            else if (insights != null)
              _buildRecommendations()
            else
              _buildNoDataState(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 12),
            Text(
              'AI is analyzing your training data...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'Unable to generate AI insights',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            error ?? 'An error occurred',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _generateInsights,
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Container(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_rounded,
              size: 32,
              color: Colors.grey[400],
            ),
            SizedBox(height: 12),
            Text(
              'Complete more training sessions to unlock AI coaching',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    if (insights?.recommendations.isEmpty ?? true) {
      return _buildNoDataState();
    }

    return Column(
      children: [
        // Generated timestamp
        if (insights?.generatedAt != null)
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                SizedBox(width: 4),
                Text(
                  'Generated ${_formatTimeAgo(insights!.generatedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

        // Recommendations list
        ...insights!.recommendations
            .map((rec) => _buildRecommendationItem(rec))
            .toList(),
      ],
    );
  }

  Widget _buildRecommendationItem(TrainingRecommendation recommendation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: recommendation.categoryColor.withOpacity(isDark ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recommendation.categoryColor.withOpacity(isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with priority and category
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: recommendation.priorityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  recommendation.priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: recommendation.priorityColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: recommendation.categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  recommendation.category.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: recommendation.categoryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Title
          Text(
            recommendation.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),

          // Description
          Text(
            recommendation.description,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.4,
            ),
          ),

          // Action items
          if (recommendation.actionItems.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Action Steps:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
            SizedBox(height: 6),
            ...recommendation.actionItems
                .map((action) => Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: recommendation.categoryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              action,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'just now';
    }
  }
}
