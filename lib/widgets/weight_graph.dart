import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../providers/theme_provider.dart'; // Import ThemeProvider
import 'package:ble_scale_app/utils/number.dart';
import '../models/info.dart';

class WeightGraph extends StatelessWidget {
  final List<FlSpot> graphData;
  final String weightUnit;

  WeightGraph({
    required this.graphData,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    // Accessing the current theme
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final gridColor = isDarkMode ? Colors.white : Colors.grey;
    final lineColor = isDarkMode ? Colors.white : Colors.black;

    // Listening to ThemeProvider for unit changes
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        String selectedUnit = themeProvider.unit;

        // Convert graph data if unit changes
        List<FlSpot> convertedGraphData = graphData.map((spot) {
          double yValue = spot.y;
          if (selectedUnit == Info.Pounds && weightUnit == Info.Kilogram) {
            yValue = convertKgToLbs(yValue);
          } else if (selectedUnit == Info.Kilogram &&
              weightUnit == Info.Pounds) {
            yValue = convertLbsToKg(yValue);
          }
          return FlSpot(spot.x, yValue);
        }).toList();

        // Calculate maxWeight from the converted graphData
        double maxWeight = convertedGraphData.isNotEmpty
            ? convertedGraphData
                .map((spot) => spot.y)
                .reduce((a, b) => a > b ? a : b)
            : 0.0;

        double minY = 0;
        double maxY = 5;

        if (convertedGraphData.isNotEmpty) {
          double dataMaxY = convertedGraphData
              .map((spot) => spot.y)
              .reduce((a, b) => a > b ? a : b);
          maxY = dataMaxY > 5 ? dataMaxY : 5; // Ensure maxY is at least 5
        }

        double maxX = convertedGraphData.isNotEmpty
            ? roundToNearest10(convertedGraphData.last.x + 5)
            : 10.0; // Ensure there's a default value that's a multiple of 10

        double interval = (maxX - 0) / 10;
        double chartHeight = 200.0; // The height of the chart (from SizedBox)
        double chartWidth = 800.0;

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
                  color: textColor,
                ),
              ),
            ),
            SizedBox(
              height: chartHeight,
              width: chartWidth,
              child: Stack(
                children: [
                  LineChart(
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
                      borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: gridColor, width: 1)),
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
                                  style:
                                      TextStyle(fontSize: 14, color: textColor),
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
                                  style:
                                      TextStyle(fontSize: 14, color: textColor),
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
                          spots: convertedGraphData,
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
                  if (convertedGraphData.isEmpty) // Overlay text when no data
                    Center(
                      child: Container(
                        color: Colors.black
                            .withOpacity(0.5), // Semi-transparent background
                        child: Text(
                          'No data available',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
