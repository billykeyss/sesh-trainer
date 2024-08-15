import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeightGraph extends StatelessWidget {
  final List<FlSpot> graphData;

  WeightGraph({required this.graphData});

  @override
  Widget build(BuildContext context) {
    double minY = 0;
    double maxY = 5;

    if (graphData.isNotEmpty) {
      double dataMaxY = graphData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      maxY = dataMaxY > 5 ? dataMaxY : 5; // Ensure maxY is at least 5
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          titlesData: FlTitlesData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: graphData,
              isCurved: false,
              color: Colors.blue,
              barWidth: 2,
              belowBarData: BarAreaData(show: true),
            ),
          ],
          minY: minY,
          maxY: maxY + 5,
        ),
      ),
    );
  }
}
