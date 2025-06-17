import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/session_database.dart';
import '../providers/theme_provider.dart';
import '../widgets/ai_recommendations_card.dart';
import '../services/llm_insights_service.dart';

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
  bool loadingTips = false;

  @override
  void initState() {
    super.initState();
    _database = SessionDatabase();
    _loadSessions();
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

      // Load quick tips if we have recent sessions
      if (sessions.isNotEmpty) {
        _loadQuickTips();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading training data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadQuickTips() async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating quick tips: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

                // Performance Analysis Section (you can add more sections here)
                _buildPerformanceAnalysisSection(),
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
                    onPressed: _loadQuickTips,
                    tooltip: 'Refresh tips',
                  ),
              ],
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
                            color: Colors.green.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.2),
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
                                    color: Colors.grey[800],
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

  Widget _buildPerformanceAnalysisSection() {
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
                Icon(Icons.analytics_rounded, color: Colors.blue),
                SizedBox(width: 12),
                Text(
                  'Performance Analysis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Basic analytics (extend with your existing insights_page.dart content)',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Sessions: ${sessions.length}',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add your existing analytics from insights_page.dart here',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
