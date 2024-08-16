import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/number.dart';
import '../widgets/weight_graph.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert'; // For jsonEncode

class SessionDetailsPage extends StatelessWidget {
  final List<FlSpot> graphData;
  final double maxWeight;
  final int sessionStartTime;
  final double totalLoad;
  final double averageWeight;
  final String elapsedTimeString;
  final int elapsedTimeMs;
  final String weightUnit;

  final ScreenshotController screenshotController = ScreenshotController();

  SessionDetailsPage({
    required this.graphData,
    required this.maxWeight,
    required this.sessionStartTime,
    required this.totalLoad,
    required this.averageWeight,
    required this.elapsedTimeString,
    required this.elapsedTimeMs,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareSessionDetails(context),
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () => _saveSessionDetails(context),
          ),
        ],
      ),
      body: Screenshot(
        controller: screenshotController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              WeightGraph(
                  graphData: graphData), // Reference to WeightGraph component
              const SizedBox(height: 16.0),
              ListTile(
                title: const Text('Session Time'),
                trailing: Text(
                    '${DateFormat('MMM d, yyyy, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(sessionStartTime))}'),
              ),
              ListTile(
                title: const Text('Max Pull'),
                trailing: Text('${maxWeight.toStringAsFixed(2)} $weightUnit'),
              ),
              ListTile(
                title: const Text('80% Pull'),
                trailing:
                    Text('${(maxWeight * 0.8).toStringAsFixed(2)} $weightUnit'),
              ),
              ListTile(
                title: const Text('20% Pull'),
                trailing:
                    Text('${(maxWeight * 0.2).toStringAsFixed(2)} $weightUnit'),
              ),
              ListTile(
                title: const Text('Average Pull'),
                trailing: Text('$averageWeight $weightUnit'),
              ),
              ListTile(
                title: const Text('Total Load (kg*s)'),
                trailing: Text('${totalLoad.toStringAsFixed(2)} $weightUnit*s'),
              ),
              ListTile(
                title: const Text('Elapsed Time'),
                trailing: Text(elapsedTimeString),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveSessionDetails(BuildContext context) async {
  try {
    // Create a table of graphData
    StringBuffer graphDataTable = StringBuffer();
    graphDataTable.writeln('\n\nGraph Data:');
    graphDataTable.writeln('Time (s)\tWeight ($weightUnit)');
    for (var spot in graphData) {
      graphDataTable.writeln('${spot.x.toStringAsFixed(2)}\t\t${spot.y.toStringAsFixed(2)}');
    }

    // Convert data to a JSON-encoded string format including the graph data
    final Map<String, dynamic> sessionData = {
      'sessionTime': DateFormat('MMM d, yyyy, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(sessionStartTime)),
      'sessionTimeEpochMs': sessionStartTime,
      'maxPull': maxWeight.toStringAsFixed(2),
      '80Pull': (maxWeight * 0.8).toStringAsFixed(2),
      '20Pull': (maxWeight * 0.2).toStringAsFixed(2),
      'averagePull': averageWeight,
      'totalLoad': totalLoad.toStringAsFixed(2),
      'elapsedTime': elapsedTimeString,
      'elapsedTimeMs': elapsedTimeMs,
      'graphData': graphData.map((spot) => {'x': spot.x, 'y': spot.y}).toList(),
    };

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/session_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(filePath);
    await file.writeAsString(jsonEncode(sessionData));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Session saved successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving session details: $e')),
    );
  }
}

  void _shareSessionDetails(BuildContext context) async {
    try {
      // Capture screenshot
      final Uint8List? screenshot = await screenshotController.capture();
      if (screenshot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to capture screenshot')));
        return;
      }

      // Create a table of graphData
      StringBuffer graphDataTable = StringBuffer();
      graphDataTable.writeln('\n\nGraph Data:');
      graphDataTable.writeln('Time (s)\tWeight ($weightUnit)');
      for (var spot in graphData) {
        graphDataTable.writeln(
            '${spot.x.toStringAsFixed(2)}\t\t${spot.y.toStringAsFixed(2)}');
      }

      // Convert data to a shareable string format including the graph data
      final String sessionData = '''
Session Time: ${DateFormat('MMM d, yyyy, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(sessionStartTime))}
Max Pull: ${maxWeight.toStringAsFixed(2)} $weightUnit
80% Pull: ${(maxWeight * 0.8).toStringAsFixed(2)} $weightUnit
20% Pull: ${(maxWeight * 0.2).toStringAsFixed(2)} $weightUnit
Average Pull: $averageWeight $weightUnit
Total Load: ${totalLoad.toStringAsFixed(2)} $weightUnit*s
Elapsed Time: $elapsedTimeString
$graphDataTable
''';

      // Save the screenshot to a temporary file
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/session_screenshot.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(screenshot);

      // Share the screenshot and data
      await Share.shareXFiles(
        [XFile(imagePath, mimeType: 'image/png')],
        text: sessionData,
        subject: 'Session Details',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing session details: $e')));
    }
  }
}
