import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../providers/theme_provider.dart'; // Import ThemeProvider
import 'package:sesh_trainer/utils/number.dart';
import '../models/info.dart';

class WeightGraph extends StatelessWidget {
  final List<FlSpot> graphData;
  final String weightUnit;
  final double? height;
  final bool showHeader;
  final bool showLegend;

  WeightGraph({
    required this.graphData,
    required this.weightUnit,
    this.height,
    this.showHeader = true,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Modern color scheme
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[50];
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final primaryColor = Colors.blue;
    final accentColor = Colors.purple;
    final textColor = isDarkMode ? Colors.white : Colors.grey[800];
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final gridColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

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

        // Calculate chart bounds
        double maxWeight = convertedGraphData.isNotEmpty
            ? convertedGraphData
                .map((spot) => spot.y)
                .reduce((a, b) => a > b ? a : b)
            : 0.0;

        double minY = 0;
        double maxY = maxWeight > 5 ? maxWeight * 1.1 : 5;
        double maxX = convertedGraphData.isNotEmpty
            ? roundToNearest10(convertedGraphData.last.x + 5)
            : 10.0;

        // Calculate performance zones
        double zone1 = maxWeight * 0.2; // Light effort
        double zone2 = maxWeight * 0.6; // Moderate effort
        double zone3 = maxWeight * 0.8; // High effort

        return Container(
          margin: showHeader ? EdgeInsets.all(16) : EdgeInsets.zero,
          decoration: showHeader
              ? BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black26
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                )
              : null,
          child: Column(
            children: [
              // Header
              if (showHeader)
                Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withOpacity(0.2),
                              accentColor.withOpacity(0.1)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.show_chart,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Force Over Time',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              convertedGraphData.isNotEmpty
                                  ? 'Peak: ${maxWeight.toStringAsFixed(1)} $selectedUnit'
                                  : 'No data recorded',
                              style: TextStyle(
                                fontSize: 14,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Chart
              Container(
                height: height ?? 280,
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: convertedGraphData.isEmpty
                    ? _buildEmptyState(context, isDarkMode)
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: maxY / 5,
                            verticalInterval: maxX / 8,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: gridColor?.withOpacity(0.3) ??
                                  Colors.grey.withOpacity(0.3),
                              strokeWidth: 1,
                            ),
                            getDrawingVerticalLine: (value) => FlLine(
                              color: gridColor?.withOpacity(0.3) ??
                                  Colors.grey.withOpacity(0.3),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                interval: maxY / 5,
                                getTitlesWidget: (value, meta) => Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subtitleColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: maxX / 6,
                                getTitlesWidget: (value, meta) => Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${value.toInt()}s',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subtitleColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          lineBarsData: [
                            // Performance zones (background)
                            if (maxWeight > 0) ...[
                              _buildZoneLine(0, zone1, maxX,
                                  Colors.green.withOpacity(0.1)),
                              _buildZoneLine(zone1, zone2, maxX,
                                  Colors.yellow.withOpacity(0.1)),
                              _buildZoneLine(zone2, zone3, maxX,
                                  Colors.orange.withOpacity(0.1)),
                              _buildZoneLine(zone3, maxY, maxX,
                                  Colors.red.withOpacity(0.1)),
                            ],

                            // Main data line
                            LineChartBarData(
                              spots: convertedGraphData,
                              isCurved: true,
                              curveSmoothness: 0.3,
                              gradient: LinearGradient(
                                colors: [primaryColor, accentColor],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: convertedGraphData.length < 50,
                                getDotPainter:
                                    (spot, percent, barData, index) =>
                                        FlDotCirclePainter(
                                  radius: 3,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: primaryColor,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.3),
                                    accentColor.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                          minY: minY,
                          maxY: maxY,
                          minX: 0,
                          maxX: maxX,
                        ),
                      ),
              ),

              // Legend/Info bar
              if (showLegend && convertedGraphData.isNotEmpty)
                Container(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLegendItem('Duration', '${maxX.toInt()}s',
                          Icons.timer, Colors.blue),
                      _buildLegendItem(
                          'Peak',
                          '${maxWeight.toStringAsFixed(1)}',
                          Icons.trending_up,
                          Colors.orange),
                      _buildLegendItem('Unit', selectedUnit,
                          Icons.fitness_center, Colors.green),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.show_chart,
              size: 48,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No Training Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start a session to see your force curve',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildZoneLine(
      double startY, double endY, double maxX, Color color) {
    return LineChartBarData(
      spots: [
        FlSpot(0, startY),
        FlSpot(maxX, startY),
        FlSpot(maxX, endY),
        FlSpot(0, endY),
        FlSpot(0, startY),
      ],
      isCurved: false,
      color: Colors.transparent,
      barWidth: 0,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color,
      ),
    );
  }
}
