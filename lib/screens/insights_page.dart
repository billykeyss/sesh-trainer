import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/session_database.dart';
import '../widgets/weight_graph.dart';
import '../utils/number.dart';
import '../widgets/display_card.dart'; // Import the DisplayCard widget

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
          content: Text('Error loading sessions: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Insights'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (sessions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Insights'),
        ),
        body: Center(
          child: Text(
            'No sessions available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // Calculate aggregates
    final totalSessions = sessions.length;
    final totalDuration = sessions.map((s) => s.elapsedTimeMs).reduce((a, b) => a + b);
    final averageMaxWeight = sessions
        .map((s) => calculateMaxWeightFromJson(s.graphData))
        .reduce((a, b) => a + b) /
        totalSessions;
    final heaviestPull = sessions
        .map((s) => calculateMaxWeightFromJson(s.graphData))
        .reduce((a, b) => a > b ? a : b);
    final lightestPull = sessions
        .map((s) => calculateMinWeightFromJson(s.graphData))
        .reduce((a, b) => a < b ? a : b);

    // Prepare graph data for max weight timeline
    final timelineData = _getTimelineData(sessions);

    return Scaffold(
      appBar: AppBar(
        title: Text('Insights'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Max Weight Timeline',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              child: WeightGraph(
                graphData: timelineData,
                weightUnit: 'lbs', // or 'kgs' based on your app's configuration
              ),
            ),
            GridView.count(
              crossAxisCount: 2, // Number of columns
              childAspectRatio: 1,
              padding: const EdgeInsets.all(8.0),
              physics: NeverScrollableScrollPhysics(), // Prevent scrolling inside grid
              shrinkWrap: true, // Allows the grid to take up only as much space as it needs
              children: [
                DisplayCard(
                  title: 'Total Sessions',
                  value: '$totalSessions',
                  unit: '',
                ),
                DisplayCard(
                  title: 'Total Duration',
                  value: formatElapsedTimeIntToString(totalDuration),
                  unit: '',
                ),
                DisplayCard(
                  title: 'Average Max Weight',
                  value: '${averageMaxWeight.toStringAsFixed(2)}',
                  unit: 'lbs', // or 'kgs' based on your app's configuration
                ),
                DisplayCard(
                  title: 'Heaviest Pull',
                  value: '${heaviestPull.toStringAsFixed(2)}',
                  unit: 'lbs', // or 'kgs' based on your app's configuration
                ),
                DisplayCard(
                  title: 'Lightest Pull',
                  value: '${lightestPull.toStringAsFixed(2)}',
                  unit: 'lbs', // or 'kgs' based on your app's configuration
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getTimelineData(List<Session> sessions) {
    List<FlSpot> spots = [];
    sessions.sort((a, b) => a.sessionTime.compareTo(b.sessionTime));
    for (int i = 0; i < sessions.length; i++) {
      final maxWeight = calculateMaxWeightFromJson(sessions[i].graphData);
      spots.add(FlSpot(i.toDouble(), maxWeight));
    }
    return spots;
  }
}
