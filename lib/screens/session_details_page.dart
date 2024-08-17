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
import 'dart:convert';
import 'dart:math';

class SessionDetailsPage extends StatefulWidget {
  final List<FlSpot> graphData;
  final double maxWeight;
  final int sessionStartTime;
  final double totalLoad;
  final double averageWeight;
  final String elapsedTimeString;
  final int elapsedTimeMs;
  final String weightUnit;
  final String sessionName;

  SessionDetailsPage({
    required this.graphData,
    required this.maxWeight,
    required this.sessionStartTime,
    required this.totalLoad,
    required this.averageWeight,
    required this.elapsedTimeString,
    required this.elapsedTimeMs,
    required this.weightUnit,
    String? sessionName,
  }) : sessionName = sessionName ??
            '${DateFormat('MMM d, yyyy, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(sessionStartTime))}';

  @override
  _SessionDetailsPageState createState() => _SessionDetailsPageState();
}

class _SessionDetailsPageState extends State<SessionDetailsPage> {
  final ScreenshotController screenshotController = ScreenshotController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.sessionName;
    _checkAndSaveSession(); // Automatically save the session on page load
  }

  void _checkAndSaveSession() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/${widget.sessionName}';
    final file = File(filePath);

    if (!await file.exists()) {
      _saveSessionDetails(context, widget.sessionName);
    }
  }

  void _renameSessionFile(BuildContext context, String newName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final oldFilePath = '${directory.path}/${widget.sessionName}';
      final newFilePath = '${directory.path}/$newName';

      final oldFile = File(oldFilePath);
      final newFile = File(newFilePath);

      if (await oldFile.exists()) {
        await oldFile.rename(newFilePath); // Rename the file
      } else {
        _saveSessionDetails(context,
            newName); // If the file doesn't exist, save it as a new session
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
    // Filter out weights that are above 0
    List<double> weights =
        graphData.where((spot) => spot.y > 0).map((spot) => spot.y).toList();

    if (weights.isEmpty) {
      // Return 0 if no valid weights are available
      return 0.0;
    }

    // Calculate mean weight
    double meanWeight = weights.reduce((a, b) => a + b) / weights.length;

    // Calculate variance
    double variance = weights
            .map((weight) => (weight - meanWeight) * (weight - meanWeight))
            .reduce((a, b) => a + b) /
        weights.length;

    // Calculate standard deviation
    double standardDeviation = sqrt(variance);

    return standardDeviation.toPrecision(2);
  }

  @override
  Widget build(BuildContext context) {
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
              _renameSessionFile(context, newName); // Call rename function
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
                    child: WeightGraph(graphData: widget.graphData),
                  ),
                ),
                const SizedBox(height: 16.0),
                // ListTiles with enhanced UI
                _buildDetailCard(
                  title: 'Session Time',
                  trailing:
                      '${DateFormat('MMM d, yyyy, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(widget.sessionStartTime))}',
                ),
                _buildDetailCard(
                  title: 'Elapsed Time',
                  trailing: widget.elapsedTimeString,
                ),
                _buildDetailCard(
                  title: 'Max Pull',
                  trailing:
                      '${widget.maxWeight.toStringAsFixed(2)} ${widget.weightUnit}',
                ),
                _buildDetailCard(
                  title: '80% Pull',
                  trailing:
                      '${(widget.maxWeight * 0.8).toStringAsFixed(2)} ${widget.weightUnit}',
                ),
                _buildDetailCard(
                  title: '20% Pull',
                  trailing:
                      '${(widget.maxWeight * 0.2).toStringAsFixed(2)} ${widget.weightUnit}',
                ),
                _buildDetailCard(
                  title: 'Average Pull',
                  trailing: '${widget.averageWeight} ${widget.weightUnit}',
                ),
                _buildDetailCard(
                  title: 'Total Load (${widget.weightUnit}*s)',
                  trailing:
                      '${widget.totalLoad.toStringAsFixed(2)} ${widget.weightUnit}*s',
                ),
                _buildDetailCard(
                  title: 'Standard Deviation',
                  trailing: '${calculateForceVariability(widget.graphData)}',
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
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
          ),
        ),
        trailing: Text(
          trailing,
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.black54,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      ),
    );
  }

  void _saveSessionDetails(BuildContext context, String name) async {
    try {
      // Create a table of graphData
      StringBuffer graphDataTable = StringBuffer();
      graphDataTable.writeln('\n\nGraph Data:');
      graphDataTable.writeln('Time (s)\tWeight (${widget.weightUnit})');
      for (var spot in widget.graphData) {
        graphDataTable.writeln(
            '${spot.x.toStringAsFixed(2)}\t\t${spot.y.toStringAsFixed(2)}');
      }

      // Convert data to a JSON-encoded string format including the graph data
      final Map<String, dynamic> sessionData = {
        'sessionTime': DateFormat('MMM d, yyyy, h:mm a').format(
            DateTime.fromMillisecondsSinceEpoch(widget.sessionStartTime)),
        'sessionTimeEpochMs': widget.sessionStartTime,
        'maxPull': widget.maxWeight.toStringAsFixed(2),
        '80Pull': (widget.maxWeight * 0.8).toStringAsFixed(2),
        '20Pull': (widget.maxWeight * 0.2).toStringAsFixed(2),
        'averagePull': widget.averageWeight,
        'totalLoad': widget.totalLoad.toStringAsFixed(2),
        'elapsedTime': widget.elapsedTimeString,
        'elapsedTimeMs': widget.elapsedTimeMs,
        'weightUnit': widget.weightUnit,
        'graphData':
            widget.graphData.map((spot) => {'x': spot.x, 'y': spot.y}).toList(),
      };

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$name';
      final file = File(filePath);
      await file.writeAsString(jsonEncode(sessionData));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session saved as "$name" successfully!')),
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
      graphDataTable.writeln('Time (s)\tWeight (${widget.weightUnit})');
      for (var spot in widget.graphData) {
        graphDataTable.writeln(
            '${spot.x.toStringAsFixed(2)}\t\t${spot.y.toStringAsFixed(2)}');
      }

      // Convert data to a shareable string format including the graph data
      final String sessionData = '''
Session Time: ${DateFormat('MMM d, yyyy, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(widget.sessionStartTime))}
Max Pull: ${widget.maxWeight.toStringAsFixed(2)} ${widget.weightUnit}
80% Pull: ${(widget.maxWeight * 0.8).toStringAsFixed(2)} ${widget.weightUnit}
20% Pull: ${(widget.maxWeight * 0.2).toStringAsFixed(2)} ${widget.weightUnit}
Average Pull: ${widget.averageWeight} ${widget.weightUnit}
Total Load: ${widget.totalLoad.toStringAsFixed(2)} ${widget.weightUnit}*s
Elapsed Time: ${widget.elapsedTimeString}
Standard Deviation: ${calculateForceVariability(widget.graphData)}
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
