import 'package:flutter/material.dart';
import 'package:sesh_trainer/widgets/leaderboard.dart'; // Update with the correct path

class LeaderboardPage extends StatefulWidget {
  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  bool _isPreviewMode = false; // Update this if needed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard'),
        actions: [
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Leaderboard(
              isPreviewMode: _isPreviewMode,
            ),
          ),
        ],
      ),
    );
  }
}
