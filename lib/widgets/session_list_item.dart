import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/session_database.dart';
import '../utils/number.dart';

class SessionListItem extends StatelessWidget {
  final Session session;
  final bool isDarkMode;
  final void Function(Session) onViewDetails;
  final void Function(Session) onDelete;
  final void Function(Session) onRename;

  const SessionListItem({
    required this.session,
    required this.isDarkMode,
    required this.onViewDetails,
    required this.onDelete,
    required this.onRename,
  });

  String _formatElapsedTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$minutes:$seconds";
  }

  double _calculateMaxWeight(String graphData) {
    final List<dynamic> data = jsonDecode(graphData);
    final List<FlSpot> spots = data.map((item) => FlSpot(item['x'], item['y'])).toList();
    if (spots.isEmpty) return 0.0;
    return spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final elapsedTime = formatElapsedTimeIntToString(session.elapsedTimeMs);
    final maxWeight = _calculateMaxWeight(session.graphData);
    final weightUnit = session.weightUnit;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2), // Changes position of shadow
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            session.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last modified: ${DateFormat('MMM d, yyyy').format(session.sessionTime)}',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              SizedBox(height: 4.0), // Adding a small gap
              Text(
                'Elapsed Time: $elapsedTime',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              SizedBox(height: 2.0), // Adding a small gap
              Text(
                'Max Weight: ${maxWeight.toStringAsFixed(1)} $weightUnit',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        onTap: () => onViewDetails(session),
        trailing: Wrap(
          spacing: 0, // Space between two icons
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => onRename(session),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(session),
            ),
          ],
        ),
      ),
    );
  }
}
