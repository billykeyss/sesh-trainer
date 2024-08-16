import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/number.dart';
import 'package:intl/intl.dart';
import '../widgets/weight_graph.dart'; // Import the WeightGraph component

class SessionDetailsPage extends StatelessWidget {
  final List<FlSpot> graphData;
  final double maxWeight;
  final int sessionStartTime;
  final double totalLoad;
  final double averageWeight;
  final String elapsedTimeString;
  final int elapsedTimeMs;
  final String weightUnit;

  SessionDetailsPage({
    required this.graphData,
    required this.maxWeight,
    required this.sessionStartTime,
    required this.totalLoad,
    required this.averageWeight,
    required this.elapsedTimeString,
    required this.elapsedTimeMs,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            WeightGraph(
                graphData: graphData), // Reference to WeightGraph component
            const SizedBox(height: 16.0),
            ListTile(
              title: const Text('Session Time'),
              trailing: Text('${DateFormat('MMM d, yyyy, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(sessionStartTime))}'),
            ),
            ListTile(
              title: const Text('Max Pull'),
              trailing: Text('${maxWeight.toStringAsFixed(2)} $weightUnit'),
            ),
            ListTile(
              title: const Text('80% Pull'),
              trailing:
                  Text('${(maxWeight * 0.8).toStringAsFixed(2)} $weightUnit'),
            ),
            ListTile(
              title: const Text('20% Pull'),
              trailing:
                  Text('${(maxWeight * 0.2).toStringAsFixed(2)} $weightUnit'),
            ),
            ListTile(
              title: const Text('Average Pull'),
              trailing: Text('$averageWeight $weightUnit'),
            ),
            ListTile(
              title: const Text('Total Load (kg*s)'),
              trailing: Text('${totalLoad.toStringAsFixed(2)} $weightUnit*s'),
            ),
            ListTile(
              title: const Text('Elapsed Time'),
              trailing: Text(elapsedTimeString),
            ),
          ],
        ),
      ),
    );
  }
}
