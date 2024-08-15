import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/number.dart';

class SessionDetailsPage extends StatelessWidget {
  final List<FlSpot> graphData;
  final double maxWeight;
  final double totalLoad;
  final double averageWeight;
  final String elapsedTimeString;
  final int elapsedTimeMs;
  final String weightUnit;

  SessionDetailsPage({
    required this.graphData,
    required this.maxWeight,
    required this.totalLoad,
    required this.averageWeight,
    required this.elapsedTimeString,
    required this.elapsedTimeMs,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    // double interval = ((elapsedTimeMs / 1000) / 10).round() / 2 * 2;
    double minY = 0;
    double maxY = 5;

    if (graphData.isNotEmpty) {
      double dataMaxY =
          graphData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      maxY = dataMaxY > 5 ? dataMaxY : 5; // Ensure maxY is at least 5
    }

    double maxX = graphData.isNotEmpty
        ? roundToNearest10(graphData.last.x)
        : 10.0; // Ensure there's a default value that's a multiple of 10

    double interval = 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40, // Space reserved for bottom titles
                        interval: interval, // No const keyword here
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: graphData,
                      isCurved: false,
                      color: Colors.blue,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: [
                        FlSpot(0, maxWeight * 0.2),
                        FlSpot(graphData.last.x, maxWeight * 0.2),
                      ],
                      isCurved: false,
                      color: Colors.red,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      dashArray: [5, 5],
                    ),
                    LineChartBarData(
                      spots: [
                        FlSpot(0, maxWeight * 0.8),
                        FlSpot(graphData.last.x, maxWeight * 0.8),
                      ],
                      isCurved: false,
                      color: Colors.green,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      dashArray: [5, 5],
                    ),
                  ],

                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ListTile(
              title: const Text('Max Pull'),
              trailing: Text('${maxWeight.toStringAsFixed(2)} $weightUnit'),
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
