import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/session_database.dart';
import '../providers/theme_provider.dart';
import '../widgets/ai_recommendations_card.dart';
import '../services/llm_insights_service.dart';
import 'dart:convert';

/// Example insights page showing how to integrate AI recommendations
/// Replace your existing insights_page.dart content with this approach
class InsightsPageWithAI extends StatefulWidget {
  @override
  _InsightsPageWithAIState createState() => _InsightsPageWithAIState();
}

class _InsightsPageWithAIState extends State<InsightsPageWithAI> {
  late final SessionDatabase _database;
  List<Session> sessions = [];
  bool isLoading = true;
  List<String> quickTips = [];
  DateTime? quickTipsGeneratedAt;
  bool loadingTips = false;

  @override
  void initState() {
    super.initState();
    _database = SessionDatabase();
    _loadCachedQuickTips();
    // Defer session loading to next frame to avoid inherited widget issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadSessions();
    });
  }

  Future<void> _loadCachedQuickTips() async {
    final db = SessionDatabase();
    final cached = await db.getLatestQuickTip();
    if (cached != null) {
      setState(() {
        quickTips = (jsonDecode(cached.tipsJson) as List<dynamic>)
            .map((e) => e.toString())
            .toList();
        quickTipsGeneratedAt = cached.generatedAt;
      });
    }
  }

  Future<void> _loadSessions() async {
    setState(() {
      isLoading = true;
    });

    try {
      sessions = await _database.getAllSessions();
      setState(() {
        isLoading = false;
      });

      // Only load cached quick tips; user can regenerate via refresh icon
      if (quickTips.isEmpty) {
        _loadCachedQuickTips();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading training data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  Future<void> _refreshQuickTips() async {
    setState(() {
      loadingTips = true;
    });

    try {
      final recentSessions = sessions
          .where((s) => DateTime.now().difference(s.sessionTime).inDays <= 7)
          .toList();

      if (recentSessions.isNotEmpty) {
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        final tips = await LLMInsightsService.generateQuickTips(
          recentSessions: recentSessions,
          weightUnit: themeProvider.unit,
        );

        setState(() {
          quickTips = tips;
          quickTipsGeneratedAt = DateTime.now();
          loadingTips = false;
        });
      } else {
        setState(() {
          quickTips = [];
          loadingTips = false;
        });
      }
    } catch (e) {
      setState(() {
        quickTips = [];
        loadingTips = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final isRateLimit = e.toString().contains('Daily limit reached');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isRateLimit
                  ? e.toString().replaceFirst('Exception: ', '')
                  : 'Error generating quick tips: $e'),
              backgroundColor: isRateLimit ? Colors.orange : Colors.red,
              duration: Duration(seconds: isRateLimit ? 5 : 3),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedUnit = themeProvider.unit;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Progress & AI Insights'),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading your training data...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (sessions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Progress & AI Insights'),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'No Training Data Yet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Complete some training sessions to unlock AI-powered insights and personalized coaching recommendations.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.fitness_center),
                  label: Text('Start Training'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Progress & AI Insights'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: _loadSessions,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSessions,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Tips Section
                if (quickTips.isNotEmpty || loadingTips)
                  Column(
                    children: [
                      _buildQuickTipsCard(),
                      SizedBox(height: 24),
                    ],
                  ),

                // AI Recommendations Section
                AIRecommendationsCard(
                  sessions: sessions,
                  weightUnit: selectedUnit,
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTipsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.2),
                        Colors.blue.withOpacity(0.1)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Tips',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'AI-generated tips based on your recent training',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!loadingTips)
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _refreshQuickTips,
                    tooltip: 'Refresh tips',
                  ),
              ],
            ),
            if (quickTipsGeneratedAt != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      'Generated ${_formatTimeAgo(quickTipsGeneratedAt!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 16),
            if (loadingTips)
              Container(
                height: 60,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Generating tips...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else if (quickTips.isNotEmpty)
              Column(
                children: quickTips
                    .map((tip) => Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (Theme.of(context).brightness ==
                                    Brightness.dark)
                                ? Colors.green.withOpacity(0.15)
                                : Colors.green.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 0.3
                                      : 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.tips_and_updates,
                                color: Colors.green,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[200]
                                        : Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              )
            else
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Complete more training sessions to get personalized tips',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0)
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours > 0)
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inMinutes > 0)
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    return 'just now';
  }
}
