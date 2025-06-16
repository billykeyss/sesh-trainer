import 'dart:typed_data';
import 'package:sesh_trainer/widgets/weight_graph.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/number.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import '../database/session_database.dart';
import '../models/info.dart';
import 'package:drift/drift.dart' as drift;
import '../providers/theme_provider.dart';
import 'package:sesh_trainer/utils/number.dart';

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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final Color cardColor = isDarkMode ? Colors.grey[800] ?? Colors.grey : Colors.white;
    final shadowColor = isDarkMode ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.2);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        String selectedUnit = themeProvider.unit;
        // Convert graph data to selected unit if necessary
        List<FlSpot> convertedGraphData = widget.graphData.map((spot) {
          double yValue = spot.y;
          if (selectedUnit == Info.Pounds && widget.weightUnit == Info.Kilogram) {
            yValue = convertKgToLbs(yValue);
          } else if (selectedUnit == Info.Kilogram && widget.weightUnit == Info.Pounds) {
            yValue = convertLbsToKg(yValue);
          }
          return FlSpot(spot.x, yValue);
        }).toList();

        final maxWeight = calculateMaxWeight(convertedGraphData);
        final averageWeight = calculateAverageWeight(convertedGraphData);
        final totalLoad = calculateTotalLoad(convertedGraphData);

        return Scaffold(
          appBar: AppBar(
            title: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              style: TextStyle(
                color: textColor, // Dynamic text color
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
              onSubmitted: (newName) {
                if (newName.isNotEmpty) {
                  _renameSession(context, newName); // Call rename function
                }
              },
            ),
            backgroundColor: theme.appBarTheme.backgroundColor, // Adjust for dark mode
            actions: [
              IconButton(
                icon: Icon(Icons.share, color: textColor),
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
                      color: cardColor, // Adjust card color for dark mode
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      shadowColor: shadowColor, // Adjust shadow color for dark mode
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: WeightGraph(
                          graphData: convertedGraphData,
                          weightUnit: selectedUnit,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // ListTiles with enhanced UI
                    _buildDetailCard(
                      title: 'Session Time',
                      trailing:
                          '${DateFormat('MMM d, yyyy, h:mm a').format(widget.sessionStartTime)}',
                      textColor: textColor,
                      cardColor: cardColor,
                      shadowColor: shadowColor,
                    ),
                    _buildDetailCard(
                      title: 'Elapsed Time',
                      trailing:
                          '${formatElapsedTimeIntToString(widget.elapsedTimeMs)}',
                      textColor: textColor,
                      cardColor: cardColor,
                      shadowColor: shadowColor,
                    ),
                    _buildDetailCard(
                      title: 'Max Pull',
                      trailing:
                          '${maxWeight.toStringAsFixed(2)} $selectedUnit',
                      textColor: textColor,
                      cardColor: cardColor,
                      shadowColor: shadowColor,
                    ),
                    _buildDetailCard(
                      title: '80% Pull',
                      trailing:
                          '${(maxWeight * 0.8).toStringAsFixed(2)} $selectedUnit',
                      textColor: textColor,
                      cardColor: cardColor,
                      shadowColor: shadowColor,
                    ),
                    _buildDetailCard(
                      title: '20% Pull',
                      trailing:
                          '${(maxWeight * 0.2).toStringAsFixed(2)} $selectedUnit',
                      textColor: textColor,
                      cardColor: cardColor,
                      shadowColor: shadowColor,
                    ),
                    _buildDetailCard(
                      title: 'Average Pull',
                      trailing:
                          '${averageWeight.toStringAsFixed(2)} $selectedUnit',
                      textColor: textColor,
                      cardColor: cardColor,
                      shadowColor: shadowColor,
                    ),
                    _buildDetailCard(
                      title: 'Total Load (${selectedUnit}*s)',
                      trailing:
                          '${totalLoad.toStringAsFixed(2)} ${selectedUnit}*s',
                      textColor: textColor,
                      cardColor: cardColor,
                      shadowColor: shadowColor,
                    ),
                    _buildDetailCard(
                      title: 'Standard Deviation',
                      trailing:
                          '${calculateForceVariability(convertedGraphData).toStringAsFixed(2)}',
                      textColor: textColor,
                      cardColor: cardColor,
                      shadowColor: shadowColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          backgroundColor: backgroundColor, // Set background for dark mode
        );
      },
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String trailing,
    required Color textColor,
    required Color cardColor,
    required Color shadowColor,
  }) {
    return Card(
      color: cardColor, // Adjust card color for dark mode
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      shadowColor: shadowColor, // Adjust shadow color for dark mode
      child: ListTile(
        contentPadding: EdgeInsets.all(8.0),
        title: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8.0), // Added horizontal padding
          child: Text(
            title,
            style: TextStyle(fontSize: 18.0, color: textColor), // Increased font size for title and color
          ),
        ),
        trailing: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8.0), // Added horizontal padding
          child: Text(
            trailing,
            style: TextStyle(
                fontSize: 16.0, color: textColor), // Increased font size for trailing text and color
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
