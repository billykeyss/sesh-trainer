import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/number.dart';

class WeightGraph extends StatelessWidget {
  final List<FlSpot> graphData;

  WeightGraph({required this.graphData});

  @override
  Widget build(BuildContext context) {
    double minY = 0;
    double maxY = 5;

    if (graphData.isNotEmpty) {
      double dataMaxY =
          graphData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      maxY = dataMaxY > 5 ? dataMaxY : 5; // Ensure maxY is at least 5
    }

    double maxX = graphData.isNotEmpty
        ? roundToNearest10(graphData.last.x + 5)
        : 10.0; // Ensure there's a default value that's a multiple of 10

    double interval = (maxX - 0) / 10;
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: true),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40, // Space reserved for bottom titles
                interval: interval,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  );
                },
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
              barWidth: 2,
              belowBarData: BarAreaData(show: true),
            ),
          ],
          minY: minY,
          maxY: (maxY + 2.5).roundToDouble(),
          minX: 0,
          maxX: graphData.isNotEmpty
              ? roundToNearest10(graphData.last.x + 5)
              : 10.0,
        ),
      ),
    );
  }
}
