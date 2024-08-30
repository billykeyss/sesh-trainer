import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/session_database.dart';
import 'package:drift/drift.dart' as drift;
import 'session_details_page.dart';
import 'dart:convert';
import '../widgets/session_list.dart'; // Import the new component

class SavedSessionsPage extends StatefulWidget {
  @override
  _SavedSessionsPageState createState() => _SavedSessionsPageState();
}

class _SavedSessionsPageState extends State<SavedSessionsPage> {
  late final SessionDatabase _database;
  List<Session> savedSessions = [];

  @override
  void initState() {
    super.initState();
    _database = SessionDatabase();
    _loadSavedSessions();
  }

  void _loadSavedSessions() async {
    final sessions = await _database.getAllSessions();
    setState(() {
      savedSessions = sessions;
    });
  }

  void _viewSessionDetails(Session session) {
    final List<FlSpot> graphData = (jsonDecode(session.graphData) as List)
        .map((item) => FlSpot(item['x'], item['y']))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionDetailsPage(
          graphData: graphData,
          sessionStartTime: session.sessionTime,
          elapsedTimeMs: session.elapsedTimeMs,
          weightUnit: session.weightUnit,
          sessionName: session.name,
        ),
      ),
    );
  }

  void _deleteSession(Session session) async {
    bool confirmed = await _showDeleteConfirmationDialog();
    if (confirmed) {
      await _database.deleteSession(session.id);
      _loadSavedSessions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session deleted')),
      );
    }
  }

  void _renameSession(Session session) async {
    final newNameController = TextEditingController(text: session.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Session'),
          content: TextField(
            controller: newNameController,
            decoration: const InputDecoration(labelText: 'New Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = newNameController.text;
                if (newName.isNotEmpty) {
                  await _database.updateSession(
                    session.copyWith(name: newName),
                  );
                  _loadSavedSessions();
                }
                Navigator.of(context).pop();
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadSavedSessions(),
          ),
        ],
      ),
      body: savedSessions.isEmpty
          ? Center(
              child: Text(
                'No sessions yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            )
          : SessionList(
              sessions: savedSessions,
              onViewDetails: _viewSessionDetails,
              onDelete: _deleteSession,
              onRename: _renameSession,
            ),
    );
  }
}
