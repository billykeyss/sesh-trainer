import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeightGraph extends StatelessWidget {
  final List<FlSpot> graphData;
  final String weightUnit;

  WeightGraph({
    required this.graphData,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate maxWeight from the graphData
    double maxWeight = graphData.isNotEmpty
        ? graphData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
        : 0.0;

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
    double chartHeight = 200.0; // The height of the chart (from SizedBox)
    double chartWidth = 800.0;

    // Accessing the current theme
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final gridColor = isDarkMode ? Colors.white : Colors.grey;
    final lineColor = isDarkMode ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 4.0), // Add bottom padding
          child: Text(
            'Weight vs. Time', // Graph Title
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        SizedBox(
          height: chartHeight,
          width: chartWidth,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: gridColor, strokeWidth: 0.5);
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(color: gridColor, strokeWidth: 0.5);
                },
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: gridColor, width: 1)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 14, color: textColor),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 14, color: textColor),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: graphData,
                  isCurved: false,
                  color: lineColor,
                  barWidth: 2,
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withOpacity(0.3),
                  ),
                ),
                LineChartBarData(
                  spots: [
                    FlSpot(0, maxWeight * 0.2),
                    FlSpot(maxX, maxWeight * 0.2),
                  ],
                  isCurved: false,
                  color: const Color.fromARGB(255, 221, 110, 102),
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  dashArray: [5, 5],
                ),
                LineChartBarData(
                  spots: [
                    FlSpot(0, maxWeight * 0.8),
                    FlSpot(maxX, maxWeight * 0.8),
                  ],
                  isCurved: false,
                  color: const Color.fromARGB(255, 114, 220, 118),
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  dashArray: [5, 5],
                ),
              ],
              minY: minY,
              maxY: (maxY + 2.5).roundToDouble(),
              minX: 0,
              maxX: maxX,
            ),
          ),
        ),
      ],
    );
  }

  double roundToNearest10(double value) {
    return (value / 10).ceilToDouble() * 10;
  }
}
