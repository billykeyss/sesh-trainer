import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StaticWeightGraph extends StatelessWidget {
  final List<FlSpot> graphData;
  double maxWeight = 0;
  
  StaticWeightGraph({
    required this.graphData,
  });

  @override
  Widget build(BuildContext context) {
    double minY = 0;
    double maxY = 5;

    if (graphData.isNotEmpty) {
      double dataMaxY =
          graphData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      maxWeight = dataMaxY;
      maxY = dataMaxY > 5 ? dataMaxY : 5; // Ensure maxY is at least 5
    }

    double maxX = graphData.isNotEmpty
        ? roundToNearest10(graphData.last.x + 5)
        : 10.0; // Ensure there's a default value that's a multiple of 10

    double interval = (maxX - 0) / 10;
    double chartHeight = 200.0; // The height of the chart (from SizedBox)
    double chartWidth = 800.0;
    double scaleFactor = chartHeight / (maxY); // Calculate pixels per unit

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              bottom: 8.0, top: 4.0), // Add bottom padding
          child: Text(
            'Weight vs. Time', // Graph Title
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: chartHeight,
          width: chartWidth,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
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
                rightTitles: const AxisTitles(
                  sideTitles:
                      SideTitles(showTitles: false), // Remove right axis
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
        )
      ],
    );
  }

  double roundToNearest10(double value) {
    return (value / 10).ceilToDouble() * 10;
  }
}
