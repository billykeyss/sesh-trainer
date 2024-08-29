import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/session_database.dart';
import 'package:drift/drift.dart' as drift;
import 'session_details_page.dart';
import 'dart:convert';

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
          : ListView.builder(
              itemCount: savedSessions.length,
              itemBuilder: (context, index) {
                final session = savedSessions[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2), // changes position of shadow
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0), // Add padding to the left of the title
                      child: Text(
                        session.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(
                          left:
                              16.0), // Add padding to the left of the subtitle
                      child: Text(
                          'Last modified: ${DateFormat('MMM d, yyyy').format(session.sessionTime)}'),
                    ),
                    onTap: () => _viewSessionDetails(session),
                    trailing: Wrap(
                      spacing: 0, // Space between two icons
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _renameSession(session),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSession(session),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
