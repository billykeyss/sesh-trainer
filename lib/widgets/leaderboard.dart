import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/leaderboard_entry.dart';
import '../models/info.dart';
import '../providers/leaderboard_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/number.dart';

class Leaderboard extends StatelessWidget {
  final bool isPreviewMode;

  Leaderboard({required this.isPreviewMode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme
    final isDarkMode = theme.brightness == Brightness.dark; // Check if dark mode is enabled

    return Consumer2<LeaderboardProvider, ThemeProvider>(
      builder: (context, leaderboardProvider, themeProvider, child) {
        final weightUnit = themeProvider.unit; // Get the default unit from ThemeProvider

        return Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    leaderboardProvider.isDaily ? 'Daily Rankings' : 'Global Rankings',
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: isDarkMode ? Colors.white : Colors.blueGrey[800],
                    ),
                  ),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    bool isDaily = !leaderboardProvider.isDaily;
                    leaderboardProvider.fetchEntries(isDaily); // Update the leaderboard mode
                  },
                  child: Text(
                    leaderboardProvider.isDaily ? 'Show Global' : 'Show Daily',
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
                SizedBox(width: 16.0),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildLeaderboardColumn(
                        'Men',
                        leaderboardProvider.maleEntries,
                        context,
                        weightUnit, // Pass weightUnit to the method
                        isDarkMode ? Colors.blueGrey[800] : Colors.blue[100],
                      ),
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: _buildLeaderboardColumn(
                        'Women',
                        leaderboardProvider.femaleEntries,
                        context,
                        weightUnit, // Pass weightUnit to the method
                        isDarkMode ? Colors.blueGrey[800] : Colors.pink[100],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeaderboardColumn(
    String title, 
    List<LeaderboardEntry> entries, 
    BuildContext context, 
    String weightUnit, // Add weightUnit parameter
    Color? backgroundColor,
  ) {
    final topEntries = isPreviewMode ? entries.take(3).toList() : entries;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor, // Set the background color
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // Position of the shadow
          ),
        ],
      ),
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: Text(
                '$title Top ${isPreviewMode ? 3 : entries.length}',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: topEntries.length,
              separatorBuilder: (context, index) => Divider(
                height: 1.0, 
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              ),
              itemBuilder: (context, index) {
                final entry = topEntries[index];
                double adjustedWeight = weightUnit == Info.Pounds ? convertKgToLbs(entry.maxWeight) : entry.maxWeight;
                String unitLabel = weightUnit == Info.Pounds ? Info.Pounds : Info.Kilogram;

                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                  title: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          flex: 1,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${index + 1}. ${entry.name}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${adjustedWeight.toStringAsFixed(1)} $unitLabel',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
