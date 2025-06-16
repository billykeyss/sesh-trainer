import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/session_database.dart';
import '../widgets/weight_graph.dart';
import '../utils/number.dart';
import '../widgets/display_card.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/info.dart';

class InsightsPage extends StatefulWidget {
  @override
  _InsightsPageState createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  late final SessionDatabase _database;
  List<Session> sessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _database = SessionDatabase();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      sessions = await _database.getAllSessions();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading training data: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedUnit = themeProvider.unit;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Progress & Insights'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (sessions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Progress & Insights'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insights,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No training data available',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Complete some training sessions to see your progress',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate aggregated training data
    final totalSessions = sessions.length;
    final totalDuration =
        sessions.map((s) => s.elapsedTimeMs).reduce((a, b) => a + b);

    // Calculate weight statistics
    final weightsInKg =
        sessions.map((s) => calculateMaxWeightFromJson(s.graphData)).toList();
    final convertedWeights = weightsInKg.map((weight) {
      return selectedUnit == Info.Pounds ? convertKgToLbs(weight) : weight;
    }).toList();

    final averageMaxWeight =
        convertedWeights.reduce((a, b) => a + b) / totalSessions;
    final bestPull = convertedWeights.reduce((a, b) => a > b ? a : b);
    final lowestPull = convertedWeights.reduce((a, b) => a < b ? a : b);

    // Calculate recent performance (last 5 sessions vs previous 5)
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
            ? '+${improvement.toStringAsFixed(1)} $selectedUnit'
            : '${improvement.toStringAsFixed(1)} $selectedUnit';
      } else {
        progressTrend = 'Need more data';
      }
    }

    // Prepare graph data for progress timeline
    final timelineData = _getTimelineData(sessions, selectedUnit);

    return Scaffold(
      appBar: AppBar(
        title: Text('Progress & Insights'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Training Progress',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Track your climbing strength over time',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Max Pull Over Time',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: WeightGraph(
                        graphData: timelineData,
                        weightUnit: selectedUnit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Training Statistics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              padding: const EdgeInsets.all(0),
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                DisplayCard(
                  title: 'Total Sessions',
                  value: '$totalSessions',
                  unit: '',
                ),
                DisplayCard(
                  title: 'Training Time',
                  value: formatElapsedTimeIntToString(totalDuration),
                  unit: '',
                ),
                DisplayCard(
                  title: 'Personal Best',
                  value: '${bestPull.toStringAsFixed(1)}',
                  unit: selectedUnit,
                ),
                DisplayCard(
                  title: 'Average Max',
                  value: '${averageMaxWeight.toStringAsFixed(1)}',
                  unit: selectedUnit,
                ),
                DisplayCard(
                  title: 'Recent Trend',
                  value: progressTrend,
                  unit: '',
                ),
                DisplayCard(
                  title: 'Range',
                  value: '${(bestPull - lowestPull).toStringAsFixed(1)}',
                  unit: selectedUnit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
