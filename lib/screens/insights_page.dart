import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/session_database.dart';
import '../widgets/weight_graph.dart';
import '../utils/number.dart';
import '../widgets/display_card.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/info.dart';
import '../widgets/ai_recommendations_card.dart';
import '../services/llm_insights_service.dart';

class InsightsPage extends StatefulWidget {
  @override
  _InsightsPageState createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  late final SessionDatabase _database;
  List<Session> sessions = [];
  bool isLoading = true;
  String selectedPeriod = 'All Time';

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedUnit = themeProvider.unit;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Progress & Insights'),
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
          title: Text('Progress & Insights'),
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
                    Icons.insights_rounded,
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
                  'Complete some training sessions to unlock detailed insights and track your climbing strength progress.',
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

    // Filter sessions based on selected period
    final filteredSessions = _getFilteredSessions(sessions, selectedPeriod);

    // Calculate comprehensive analytics
    final analytics = _calculateAnalytics(filteredSessions, selectedUnit);
    final timelineData = _getTimelineData(filteredSessions, selectedUnit);

    return Scaffold(
      appBar: AppBar(
        title: Text('Progress & Insights'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            initialValue: selectedPeriod,
            onSelected: (String value) {
              setState(() {
                selectedPeriod = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(value: 'All Time', child: Text('All Time')),
              PopupMenuItem(value: 'Last 30 Days', child: Text('Last 30 Days')),
              PopupMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(selectedPeriod, style: TextStyle(fontSize: 14)),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSessions,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(context, analytics, selectedUnit),
                SizedBox(height: 24),

                // Progress Chart
                _buildProgressChart(
                    context, timelineData, selectedUnit, isTablet),
                SizedBox(height: 24),

                // Key Metrics Grid
                _buildKeyMetricsGrid(
                    context, analytics, selectedUnit, isTablet),
                SizedBox(height: 24),

                // Performance Analytics
                _buildPerformanceAnalytics(
                    context, analytics, selectedUnit, isTablet),
                SizedBox(height: 24),

                // Training Patterns
                _buildTrainingPatterns(context, analytics, isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context,
      Map<String, dynamic> analytics, String selectedUnit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up_rounded, size: 28, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Training Progress',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tracking ${analytics['totalSessions']} sessions • ${selectedPeriod}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressChart(BuildContext context, List<FlSpot> timelineData,
      String selectedUnit, bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart_rounded, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Strength Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Maximum pull weight over time',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            WeightGraph(
              graphData: timelineData,
              weightUnit: selectedUnit,
              height: isTablet ? 250 : 200,
              showHeader: false,
              showLegend: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsGrid(BuildContext context,
      Map<String, dynamic> analytics, String selectedUnit, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900
        ? 4
        : screenWidth > 600
            ? 3
            : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics_rounded, color: Colors.purple),
            SizedBox(width: 8),
            Text(
              'Key Metrics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: isTablet ? 1.3 : 1.2,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            DisplayCard(
              title: 'Personal Best',
              value: '${analytics['bestPull'].toStringAsFixed(1)}',
              unit: selectedUnit,
              icon: Icons.emoji_events_rounded,
              accentColor: Colors.amber,
            ),
            DisplayCard(
              title: 'Average Max',
              value: '${analytics['averageMaxWeight'].toStringAsFixed(1)}',
              unit: selectedUnit,
              icon: Icons.trending_up_rounded,
              accentColor: Colors.blue,
            ),
            DisplayCard(
              title: 'Total Sessions',
              value: '${analytics['totalSessions']}',
              unit: '',
              icon: Icons.fitness_center_rounded,
              accentColor: Colors.green,
            ),
            DisplayCard(
              title: 'Training Time',
              value: analytics['totalTrainingTime'],
              unit: '',
              icon: Icons.schedule_rounded,
              accentColor: Colors.orange,
            ),
            DisplayCard(
              title: 'Recent Trend',
              value: analytics['progressTrend'],
              unit: '',
              icon: analytics['progressTrend'].contains('+')
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              accentColor: analytics['progressTrend'].contains('+')
                  ? Colors.green
                  : Colors.red,
            ),
            DisplayCard(
              title: 'Consistency',
              value: '${analytics['consistencyScore']}%',
              unit: '',
              icon: Icons.schedule_rounded,
              accentColor: Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceAnalytics(BuildContext context,
      Map<String, dynamic> analytics, String selectedUnit, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text(
              'Performance Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: isTablet ? 3 : 2,
          childAspectRatio: isTablet ? 1.4 : 1.3,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            DisplayCard(
              title: 'Strength Range',
              value: '${analytics['strengthRange'].toStringAsFixed(1)}',
              unit: selectedUnit,
              icon: Icons.compare_arrows_rounded,
              accentColor: Colors.deepPurple,
            ),
            DisplayCard(
              title: 'Improvement Rate',
              value: '${analytics['improvementRate'].toStringAsFixed(1)}',
              unit: '$selectedUnit/week',
              icon: Icons.speed_rounded,
              accentColor: Colors.cyan,
            ),
            DisplayCard(
              title: 'Best Day',
              value: analytics['bestDayOfWeek'],
              unit: '',
              icon: Icons.star_rounded,
              accentColor: Colors.pink,
            ),
            DisplayCard(
              title: 'Session Frequency',
              value: '${analytics['avgSessionsPerWeek'].toStringAsFixed(1)}',
              unit: '/week',
              icon: Icons.repeat_rounded,
              accentColor: Colors.lime,
            ),
            DisplayCard(
              title: 'Recovery Time',
              value: '${analytics['avgRecoveryDays'].toStringAsFixed(1)}',
              unit: 'days',
              icon: Icons.hotel_rounded,
              accentColor: Colors.brown,
            ),
            DisplayCard(
              title: 'Volume Trend',
              value: analytics['volumeTrend'],
              unit: '',
              icon: Icons.show_chart_rounded,
              accentColor: Colors.deepOrange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrainingPatterns(
      BuildContext context, Map<String, dynamic> analytics, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.pattern_rounded, color: Colors.teal),
            SizedBox(width: 8),
            Text(
              'Training Patterns',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                ..._buildWeeklyActivity(analytics['weeklyActivity']),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 16),
                Text(
                  'Insights & Recommendations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                ..._buildInsights(analytics),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildWeeklyActivity(Map<String, int> weeklyActivity) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxSessions = weeklyActivity.values.isEmpty
        ? 1
        : weeklyActivity.values.reduce((a, b) => a > b ? a : b);

    return days.map((day) {
      final sessions = weeklyActivity[day] ?? 0;
      final percentage = maxSessions > 0 ? sessions / maxSessions : 0.0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey[200],
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            SizedBox(
              width: 30,
              child: Text(
                '$sessions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildInsights(Map<String, dynamic> analytics) {
    List<String> insights = [];

    if (analytics['consistencyScore'] >= 80) {
      insights.add(
          '🔥 Excellent consistency! You\'re maintaining a regular training schedule.');
    } else if (analytics['consistencyScore'] >= 60) {
      insights.add(
          '👍 Good consistency. Try to maintain regular training intervals.');
    } else {
      insights
          .add('📅 Consider establishing a more consistent training routine.');
    }

    if (analytics['improvementRate'] > 1.0) {
      insights.add(
          '📈 Great progress! You\'re improving at ${analytics['improvementRate'].toStringAsFixed(1)} ${analytics['selectedUnit']}/week.');
    } else if (analytics['improvementRate'] > 0) {
      insights.add('⬆️ Steady improvement. Keep up the consistent training!');
    } else {
      insights.add(
          '💪 Focus on progressive overload to continue building strength.');
    }

    if (analytics['avgRecoveryDays'] < 1) {
      insights
          .add('⚠️ Consider longer recovery periods between intense sessions.');
    } else if (analytics['avgRecoveryDays'] > 3) {
      insights.add('🎯 Try increasing training frequency for faster progress.');
    }

    return insights
        .map((insight) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.substring(0, 2), style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.substring(3),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }

  List<Session> _getFilteredSessions(List<Session> sessions, String period) {
    final now = DateTime.now();

    switch (period) {
      case 'Last 7 Days':
        final cutoff = now.subtract(Duration(days: 7));
        return sessions.where((s) => s.sessionTime.isAfter(cutoff)).toList();
      case 'Last 30 Days':
        final cutoff = now.subtract(Duration(days: 30));
        return sessions.where((s) => s.sessionTime.isAfter(cutoff)).toList();
      default:
        return sessions;
    }
  }

  Map<String, dynamic> _calculateAnalytics(
      List<Session> sessions, String selectedUnit) {
    if (sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'totalTrainingTime': '0m',
        'bestPull': 0.0,
        'averageMaxWeight': 0.0,
        'strengthRange': 0.0,
        'progressTrend': 'No data',
        'improvementRate': 0.0,
        'consistencyScore': 0,
        'bestDayOfWeek': 'N/A',
        'avgSessionsPerWeek': 0.0,
        'avgRecoveryDays': 0.0,
        'volumeTrend': 'Stable',
        'weeklyActivity': <String, int>{},
      };
    }

    // Basic metrics
    final totalSessions = sessions.length;
    final totalDuration =
        sessions.map((s) => s.elapsedTimeMs).reduce((a, b) => a + b);

    // Weight statistics
    final weightsInKg =
        sessions.map((s) => calculateMaxWeightFromJson(s.graphData)).toList();
    final convertedWeights = weightsInKg.map((weight) {
      return selectedUnit == Info.Pounds ? convertKgToLbs(weight) : weight;
    }).toList();

    final averageMaxWeight =
        convertedWeights.reduce((a, b) => a + b) / totalSessions;
    final bestPull = convertedWeights.reduce((a, b) => a > b ? a : b);
    final lowestPull = convertedWeights.reduce((a, b) => a < b ? a : b);
    final strengthRange = bestPull - lowestPull;

    // Progress trend
    String progressTrend = 'No data';
    if (sessions.length >= 2) {
      final recentSessions = sessions.take(5).toList();
      final recentAvg = recentSessions
              .map((s) => calculateMaxWeightFromJson(s.graphData))
              .map((weight) =>
                  selectedUnit == Info.Pounds ? convertKgToLbs(weight) : weight)
              .reduce((a, b) => a + b) /
          recentSessions.length;

      if (sessions.length >= 6) {
        final previousSessions = sessions.skip(5).take(5).toList();
        final previousAvg = previousSessions
                .map((s) => calculateMaxWeightFromJson(s.graphData))
                .map((weight) => selectedUnit == Info.Pounds
                    ? convertKgToLbs(weight)
                    : weight)
                .reduce((a, b) => a + b) /
            previousSessions.length;

        final improvement = recentAvg - previousAvg;
        progressTrend = improvement > 0
            ? '+${improvement.toStringAsFixed(1)}'
            : '${improvement.toStringAsFixed(1)}';
      } else {
        progressTrend = 'Building...';
      }
    }

    // Improvement rate (weight gained per week)
    double improvementRate = 0.0;
    if (sessions.length >= 2) {
      sessions.sort((a, b) => a.sessionTime.compareTo(b.sessionTime));
      final firstWeight = selectedUnit == Info.Pounds
          ? convertKgToLbs(calculateMaxWeightFromJson(sessions.first.graphData))
          : calculateMaxWeightFromJson(sessions.first.graphData);
      final lastWeight = selectedUnit == Info.Pounds
          ? convertKgToLbs(calculateMaxWeightFromJson(sessions.last.graphData))
          : calculateMaxWeightFromJson(sessions.last.graphData);
      final daysDiff = sessions.last.sessionTime
          .difference(sessions.first.sessionTime)
          .inDays;
      if (daysDiff > 0) {
        improvementRate = (lastWeight - firstWeight) / (daysDiff / 7.0);
      }
    }

    // Consistency score (based on regular training intervals)
    int consistencyScore = 0;
    if (sessions.length >= 2) {
      sessions.sort((a, b) => a.sessionTime.compareTo(b.sessionTime));
      final intervals = <int>[];
      for (int i = 1; i < sessions.length; i++) {
        intervals.add(sessions[i]
            .sessionTime
            .difference(sessions[i - 1].sessionTime)
            .inDays);
      }
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      final variance = intervals
              .map((i) => (i - avgInterval) * (i - avgInterval))
              .reduce((a, b) => a + b) /
          intervals.length;
      consistencyScore =
          (100 * (1 / (1 + variance / 10))).round().clamp(0, 100);
    }

    // Best day of week
    final weeklyActivity = <String, int>{};
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (final session in sessions) {
      final dayName = dayNames[session.sessionTime.weekday - 1];
      weeklyActivity[dayName] = (weeklyActivity[dayName] ?? 0) + 1;
    }
    final bestDayOfWeek = weeklyActivity.entries.isEmpty
        ? 'N/A'
        : weeklyActivity.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

    // Average sessions per week
    double avgSessionsPerWeek = 0.0;
    if (sessions.length >= 2) {
      sessions.sort((a, b) => a.sessionTime.compareTo(b.sessionTime));
      final totalDays = sessions.last.sessionTime
          .difference(sessions.first.sessionTime)
          .inDays;
      avgSessionsPerWeek =
          totalDays > 0 ? (sessions.length * 7.0) / totalDays : 0.0;
    }

    // Average recovery days
    double avgRecoveryDays = 0.0;
    if (sessions.length >= 2) {
      sessions.sort((a, b) => a.sessionTime.compareTo(b.sessionTime));
      final recoveryTimes = <int>[];
      for (int i = 1; i < sessions.length; i++) {
        recoveryTimes.add(sessions[i]
            .sessionTime
            .difference(sessions[i - 1].sessionTime)
            .inDays);
      }
      avgRecoveryDays = recoveryTimes.isNotEmpty
          ? recoveryTimes.reduce((a, b) => a + b) / recoveryTimes.length
          : 0.0;
    }

    // Volume trend
    String volumeTrend = 'Stable';
    if (sessions.length >= 4) {
      final firstHalf = sessions.take(sessions.length ~/ 2).toList();
      final secondHalf = sessions.skip(sessions.length ~/ 2).toList();

      final firstHalfAvg = firstHalf
              .map((s) => calculateMaxWeightFromJson(s.graphData))
              .reduce((a, b) => a + b) /
          firstHalf.length;
      final secondHalfAvg = secondHalf
              .map((s) => calculateMaxWeightFromJson(s.graphData))
              .reduce((a, b) => a + b) /
          secondHalf.length;

      if (secondHalfAvg > firstHalfAvg * 1.05) {
        volumeTrend = 'Increasing';
      } else if (secondHalfAvg < firstHalfAvg * 0.95) {
        volumeTrend = 'Decreasing';
      }
    }

    return {
      'totalSessions': totalSessions,
      'totalTrainingTime': formatElapsedTimeIntToString(totalDuration),
      'bestPull': bestPull,
      'averageMaxWeight': averageMaxWeight,
      'strengthRange': strengthRange,
      'progressTrend': progressTrend,
      'improvementRate': improvementRate,
      'consistencyScore': consistencyScore,
      'bestDayOfWeek': bestDayOfWeek,
      'avgSessionsPerWeek': avgSessionsPerWeek,
      'avgRecoveryDays': avgRecoveryDays,
      'volumeTrend': volumeTrend,
      'weeklyActivity': weeklyActivity,
    };
  }

  List<FlSpot> _getTimelineData(List<Session> sessions, String unit) {
    List<FlSpot> spots = [];
    // Sort by session time to show chronological progress
    sessions.sort((a, b) => a.sessionTime.compareTo(b.sessionTime));
    for (int i = 0; i < sessions.length; i++) {
      double maxWeight = calculateMaxWeightFromJson(sessions[i].graphData);
      if (unit == Info.Pounds) {
        maxWeight = convertKgToLbs(maxWeight);
      }
      spots.add(FlSpot(i.toDouble(), maxWeight));
    }
    return spots;
  }
}
