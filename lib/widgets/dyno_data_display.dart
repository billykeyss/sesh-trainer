import 'package:sesh_trainer/providers/dyno_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/info.dart';

import '../utils/number.dart';
import 'display_card.dart';
import '../providers/theme_provider.dart'; // Import the ThemeProvider

class DynoDataDisplay extends StatelessWidget {
  final int crossAxisCount;

  DynoDataDisplay({
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<DynoDataProvider, ThemeProvider>(
      builder: (context, dynoDataProvider, themeProvider, child) {
        double? weight = dynoDataProvider.weight;
        final String selectedUnit = themeProvider.unit;
        final Map<String, double?> maxWeights = dynoDataProvider.maxWeights;
        final Stopwatch stopwatch = dynoDataProvider.stopwatch;
        final bool isActive = dynoDataProvider.recordData;

        // Convert weight to selected unit if necessary
        if (selectedUnit == Info.Pounds &&
            dynoDataProvider.weightUnit == Info.Kilogram) {
          weight = weight != null ? convertKgToLbs(weight) : null;
        } else if (selectedUnit == Info.Kilogram &&
            dynoDataProvider.weightUnit == Info.Pounds) {
          weight = weight != null ? convertLbsToKg(weight) : null;
        }

        double? maxWeight = maxWeights[dynoDataProvider.weightUnit];
        if (selectedUnit == Info.Pounds &&
            dynoDataProvider.weightUnit == Info.Kilogram) {
          maxWeight = maxWeight != null ? convertKgToLbs(maxWeight) : null;
        } else if (selectedUnit == Info.Kilogram &&
            dynoDataProvider.weightUnit == Info.Pounds) {
          maxWeight = maxWeight != null ? convertLbsToKg(maxWeight) : null;
        }

        // Calculate additional metrics
        // Removed unused calculations for average weight and total load

        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header section
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isActive
                                ? [
                                    Colors.green.withOpacity(0.2),
                                    Colors.green.withOpacity(0.1)
                                  ]
                                : [
                                    Colors.grey.withOpacity(0.2),
                                    Colors.grey.withOpacity(0.1)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isActive
                              ? Icons.fitness_center
                              : Icons.pause_circle_outline,
                          color: isActive ? Colors.green : Colors.grey,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isActive ? 'Training Active' : 'Ready to Train',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[800],
                              ),
                            ),
                            Text(
                              isActive
                                  ? 'Recording session data'
                                  : 'Press Start to begin',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main metrics grid
                Container(
                  height: 280, // Further increased height
                  child: GridView.count(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.9, // Slightly taller cards
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    padding: EdgeInsets.zero,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      DisplayCard(
                        title: 'Current Pull',
                        value: '${weight?.toStringAsFixed(1) ?? '0.0'}',
                        unit: selectedUnit,
                        icon: Icons.trending_up,
                        accentColor: Colors.blue,
                        isLarge: false,
                      ),
                      DisplayCard(
                        title: 'Max Pull',
                        value: '${maxWeight?.toStringAsFixed(1) ?? '0.0'}',
                        unit: selectedUnit,
                        icon: Icons.emoji_events,
                        accentColor: Colors.orange,
                        isLarge: false,
                      ),
                      DisplayCard(
                        title: 'Session Time',
                        value: formatElapsedTime(stopwatch.elapsed),
                        unit: '',
                        icon: Icons.timer,
                        accentColor: Colors.green,
                        isLarge: false,
                      ),
                    ],
                  ),
                ),

                // Additional metrics row (if space allows and data exists)
                // Removed average and total load display
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniMetric(BuildContext context, String title, String value,
      IconData icon, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.grey[800];
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double convertKgToLbs(double kg) {
    return kg * 2.20462;
  }

  double convertLbsToKg(double lbs) {
    return lbs / 2.20462;
  }
}
