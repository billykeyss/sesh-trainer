import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import './session_details_page.dart';
import 'package:intl/intl.dart';

class SavedSessionsPage extends StatefulWidget {
  @override
  _SavedSessionsPageState createState() => _SavedSessionsPageState();
}

class _SavedSessionsPageState extends State<SavedSessionsPage> {
  List<File> savedSessions = [];

  @override
  void initState() {
    super.initState();
    _loadSavedSessions();
  }

  void _loadSavedSessions() async {
    final directory = await getApplicationDocumentsDirectory();
    final sessionFiles =
        directory.listSync().where((file) => file.path.endsWith('.json')).toList();

    setState(() {
      savedSessions = sessionFiles.map((file) => File(file.path)).toList();
    });
  }

void _viewSessionDetails(File file) async {
  final sessionData = jsonDecode(await file.readAsString());

  print(sessionData);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SessionDetailsPage(
        graphData: (sessionData['graphData'] as List)
            .map((item) => FlSpot(item['x'], item['y']))
            .toList(),
        maxWeight: double.parse(sessionData['maxPull']),
        sessionStartTime: sessionData['sessionTimeEpochMs'],  // Ensure this is a String
        totalLoad: double.parse(sessionData['totalLoad']),
        averageWeight: sessionData['averagePull'],
        elapsedTimeString: sessionData['elapsedTime'].toString(),
        elapsedTimeMs: sessionData['elapsedTimeMs'],
        weightUnit: 'kg', // Assuming all are in kg, update as necessary
      ),
    ),
  );
}


  void _deleteSession(File file) async {
    bool confirmed = await _showDeleteConfirmationDialog();
    if (confirmed) {
      await file.delete();
      setState(() {
        savedSessions.remove(file);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session deleted')),
      );
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Delete Session'),
              content: Text('Are you sure you want to delete this session?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Sessions'),
      ),
      body: ListView.builder(
        itemCount: savedSessions.length,
        itemBuilder: (context, index) {
          final file = savedSessions[index];
          return ListTile(
            title: Text(file.path.split('/').last),
            onTap: () => _viewSessionDetails(file),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteSession(file),
            ),
          );
        },
      ),
    );
  }
}
