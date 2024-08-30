import 'dart:typed_data';
import 'package:ble_scale_app/widgets/weight_graph.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/number.dart';
import '../widgets/static_weight_graph.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:math';
import '../database/session_database.dart';
import 'package:drift/drift.dart' as drift;

class SessionDetailsPage extends StatefulWidget {
  final List<FlSpot> graphData;
  final DateTime sessionStartTime;
  final int elapsedTimeMs;
  final String weightUnit;
  final String sessionName;

  SessionDetailsPage({
    required this.graphData,
    required this.sessionStartTime,
    required this.elapsedTimeMs,
    required this.weightUnit,
    required this.sessionName,
  });

  @override
  _SessionDetailsPageState createState() => _SessionDetailsPageState();
}

class _SessionDetailsPageState extends State<SessionDetailsPage> {
  final ScreenshotController screenshotController = ScreenshotController();
  final TextEditingController _nameController = TextEditingController();
  late final SessionDatabase _database;

  @override
  void initState() {
    super.initState();
    _database = SessionDatabase();
    _nameController.text = widget.sessionName;
    _checkAndSaveSession(); // Automatically save the session on page load
  }

  void _checkAndSaveSession() async {
    final sessionExists = await _sessionExists(widget.sessionName);
    if (!sessionExists) {
      _saveSessionDetails(context, widget.sessionName);
    }
  }

  Future<bool> _sessionExists(String name) async {
    final sessions = await _database.getAllSessions();
    return sessions.any((session) => session.name == name);
  }

  void _renameSession(BuildContext context, String newName) async {
    try {
      final sessionExists = await _sessionExists(widget.sessionName);
      if (sessionExists) {
        final sessions = await _database.getAllSessions();
        final session =
            sessions.firstWhere((s) => s.name == widget.sessionName);
        await _database.insertSession(
          SessionsCompanion(
            id: drift.Value(session.id),
            name: drift.Value(newName),
            email: drift.Value(session.email),
            elapsedTimeMs: drift.Value(session.elapsedTimeMs),
            weightUnit: drift.Value(session.weightUnit),
            sessionTime: drift.Value(session.sessionTime),
            graphData: drift.Value(session.graphData),
            data: drift.Value(session.data),
          ),
        );
        await _database.deleteSession(session.id);
      } else {
        _saveSessionDetails(context, newName);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text('Session renamed to "$newName" successfully!'),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text('Error renaming session: $e'),
          ),
        ),
      );
    }
  }

  double calculateMaxWeight(List<FlSpot> graphData) {
    return graphData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
  }

  double calculateAverageWeight(List<FlSpot> graphData) {
    List<double> weights = graphData.map((spot) => spot.y).toList();
    if (weights.isEmpty) return 0.0;
    return weights.reduce((a, b) => a + b) / weights.length;
  }

  double calculateTotalLoad(List<FlSpot> graphData) {
    return graphData.fold(0.0, (total, spot) => total + spot.y);
  }

  double calculateForceVariability(List<FlSpot> graphData) {
    List<double> weights =
        graphData.where((spot) => spot.y > 0).map((spot) => spot.y).toList();
    if (weights.isEmpty) return 0.0;
    double meanWeight = weights.reduce((a, b) => a + b) / weights.length;
    double variance = weights
            .map((weight) => (weight - meanWeight) * (weight - meanWeight))
            .reduce((a, b) => a + b) /
        weights.length;
    double standardDeviation = sqrt(variance);
    return standardDeviation;
  }

  @override
  Widget build(BuildContext context) {
    final maxWeight = calculateMaxWeight(widget.graphData);
    final averageWeight = calculateAverageWeight(widget.graphData);
    final totalLoad = calculateTotalLoad(widget.graphData);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
          style: TextStyle(
            color: Colors.black, // Changed text color to black
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          onSubmitted: (newName) {
            if (newName.isNotEmpty) {
              _renameSession(context, newName); // Call rename function
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareSessionDetails(context),
          ),
        ],
      ),
      body: Screenshot(
        controller: screenshotController,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Graph Widget
                Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: WeightGraph(
                        graphData: widget.graphData,
                        weightUnit: widget.weightUnit),
                  ),
                ),
                const SizedBox(height: 16.0),
                // ListTiles with enhanced UI
                _buildDetailCard(
                  title: 'Session Time',
                  trailing:
                      '${DateFormat('MMM d, yyyy, h:mm a').format(widget.sessionStartTime)}',
                ),
                _buildDetailCard(
                  title: 'Elapsed Time',
                  trailing:
                      '${formatElapsedTimeToString(widget.elapsedTimeMs)}',
                ),
                _buildDetailCard(
                  title: 'Max Pull',
                  trailing:
                      '${maxWeight.toStringAsFixed(2)} ${widget.weightUnit}',
                ),
                _buildDetailCard(
                  title: '80% Pull',
                  trailing:
                      '${(maxWeight * 0.8).toStringAsFixed(2)} ${widget.weightUnit}',
                ),
                _buildDetailCard(
                  title: '20% Pull',
                  trailing:
                      '${(maxWeight * 0.2).toStringAsFixed(2)} ${widget.weightUnit}',
                ),
                _buildDetailCard(
                  title: 'Average Pull',
                  trailing:
                      '${averageWeight.toStringAsFixed(2)} ${widget.weightUnit}',
                ),
                _buildDetailCard(
                  title: 'Total Load (${widget.weightUnit}*s)',
                  trailing:
                      '${totalLoad.toStringAsFixed(2)} ${widget.weightUnit}*s',
                ),
                _buildDetailCard(
                  title: 'Standard Deviation',
                  trailing:
                      '${calculateForceVariability(widget.graphData).toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({required String title, required String trailing}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(8.0),
        title: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8.0), // Added horizontal padding
          child: Text(
            title,
            style: TextStyle(fontSize: 18.0), // Increased font size for title
          ),
        ),
        trailing: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8.0), // Added horizontal padding
          child: Text(
            trailing,
            style: TextStyle(
                fontSize: 16.0), // Increased font size for trailing text
          ),
        ),
      ),
    );
  }

  void _saveSessionDetails(BuildContext context, String name) async {
    try {
      final newSession = SessionsCompanion(
        name: drift.Value(name),
        email: drift.Value(''), // Provide default or empty value
        elapsedTimeMs: drift.Value(widget.elapsedTimeMs),
        weightUnit: drift.Value(widget.weightUnit),
        sessionTime: drift.Value(widget.sessionStartTime),
        graphData: drift.Value(jsonEncode(widget.graphData
            .map((spot) => {'x': spot.x, 'y': spot.y})
            .toList())),
        data: drift.Value(''),
      );
      await _database.insertSession(newSession);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text('Session "$name" saved successfully!'),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text('Error saving session: $e'),
          ),
        ),
      );
    }
  }

  void _shareSessionDetails(BuildContext context) async {
    try {
      final Uint8List? screenshot = await screenshotController.capture();
      if (screenshot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: Text('Failed to capture screenshot.'),
            ),
          ),
        );
        return;
      }

      final directory = await Directory.systemTemp.createTemp();
      final imagePath = '${directory.path}/screenshot.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(screenshot);

      await Share.shareXFiles([XFile(imagePath)]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text('Error sharing session: $e'),
          ),
        ),
      );
    }
  }
}
