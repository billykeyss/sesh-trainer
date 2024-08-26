import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/leaderboard_entry.dart';
import '../providers/leaderboard_provider.dart';

class Leaderboard extends StatelessWidget {
  final bool isPreviewMode;

  Leaderboard({required this.isPreviewMode});

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaderboardProvider>(
      builder: (context, leaderboardProvider, child) {
        return Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    leaderboardProvider.isDaily
                        ? 'Daily Rankings'
                        : 'Global Rankings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    bool isDaily = !leaderboardProvider.isDaily;
                    leaderboardProvider.fetchEntries(isDaily); // Call fetchEntries to update the state
                  },
                  child: Text(
                    leaderboardProvider.isDaily
                        ? 'Show Global Leaderboard'
                        : 'Show Daily Leaderboard',
                  ),
                ),
              ],
            ),
            // Header for Daily/Global Rankings

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildLeaderboardColumn(
                        'Men',
                        leaderboardProvider.maleEntries,
                        context,
                      ),
                    ),
                    Container(
                      width: 1.0,
                      color: Colors.grey[300], // Color of the border
                      height: double.infinity, // Full height of the row
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: _buildLeaderboardColumn(
                        'Women',
                        leaderboardProvider.femaleEntries,
                        context,
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
      String title, List<LeaderboardEntry> entries, BuildContext context) {
    final topEntries = isPreviewMode ? entries.take(3).toList() : entries;

    return Container(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: Text(
                '$title Top ${isPreviewMode ? 3 : entries.length}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: topEntries.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1.0, color: Colors.grey[300]),
              itemBuilder: (context, index) {
                final entry = topEntries[index];
                double weightInLbs = entry.maxWeight * 2.20462;

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
                                style: TextStyle(fontSize: 16),
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
                                '${weightInLbs.toStringAsFixed(1)} lbs',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
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
