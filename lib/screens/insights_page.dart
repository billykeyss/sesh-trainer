import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/session_database.dart';
import '../widgets/weight_graph.dart';
import '../utils/number.dart';
import '../widgets/display_card.dart'; // Import the DisplayCard widget
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
          content: Text('Error loading sessions: $e'),
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

    // Calculate aggregates and convert to selected unit
    final totalSessions = sessions.length;
    final totalDuration = sessions.map((s) => s.elapsedTimeMs).reduce((a, b) => a + b);

    // Aggregate weight calculations
    final weightsInKg = sessions.map((s) => calculateMaxWeightFromJson(s.graphData)).toList();
    final convertedWeights = weightsInKg.map((weight) {
      return selectedUnit == Info.Pounds ? convertKgToLbs(weight) : weight;
    }).toList();

    final averageMaxWeight = convertedWeights.reduce((a, b) => a + b) / totalSessions;
    final heaviestPull = convertedWeights.reduce((a, b) => a > b ? a : b);
    final lightestPull = convertedWeights.reduce((a, b) => a < b ? a : b);

    // Prepare graph data for max weight timeline
    final timelineData = _getTimelineData(sessions, selectedUnit);

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
                weightUnit: selectedUnit,
              ),
            ),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1,
              padding: const EdgeInsets.all(8.0),
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
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
                  unit: selectedUnit,
                ),
                DisplayCard(
                  title: 'Heaviest Pull',
                  value: '${heaviestPull.toStringAsFixed(2)}',
                  unit: selectedUnit,
                ),
                DisplayCard(
                  title: 'Lightest Pull',
                  value: '${lightestPull.toStringAsFixed(2)}',
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
