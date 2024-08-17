import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import './session_details_page.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSavedSessions();
  }

  void _loadSavedSessions() async {
    final directory = await getApplicationDocumentsDirectory();
    final sessionFiles = directory.listSync().toList();

    setState(() {
      savedSessions = sessionFiles.map((file) => File(file.path)).toList();
    });
  }

  void _viewSessionDetails(File file) async {
    final sessionData = jsonDecode(await file.readAsString());
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionDetailsPage(
          graphData: (sessionData['graphData'] as List)
              .map((item) => FlSpot(item['x'], item['y']))
              .toList(),
          maxWeight: double.parse(sessionData['maxPull']),
          sessionStartTime:
              sessionData['sessionTimeEpochMs'], // Ensure this is a String
          totalLoad: double.parse(sessionData['totalLoad']),
          averageWeight: sessionData['averagePull'],
          elapsedTimeString: sessionData['elapsedTime'].toString(),
          elapsedTimeMs: sessionData['elapsedTimeMs'],
          weightUnit: sessionData[
              'weightUnit'], // Assuming all are in kg, update as necessary
          sessionName: path.basename(file.path),
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

  void _renameSession(File file) async {
    final currentName = file.path.split('/').last.split('.').first;
    final newNameController = TextEditingController(text: currentName);

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
                  final directory = await getApplicationDocumentsDirectory();
                  final newFile = File('${directory.path}/$newName');
                  await file.copy(newFile.path);
                  await file.delete();

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
                final file = savedSessions[index];
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
                        file.path.split('/').last,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(
                          left:
                              16.0), // Add padding to the left of the subtitle
                      child: Text(
                          'Last modified: ${DateFormat('MMM d, yyyy').format(file.lastModifiedSync())}'),
                    ),
                    onTap: () => _viewSessionDetails(file),
                    trailing: Wrap(
                      spacing: 0, // Space between two icons
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _renameSession(file),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSession(file),
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
