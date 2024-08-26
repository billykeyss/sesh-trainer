import 'package:ble_scale_app/providers/dyno_data_provider.dart';
import 'package:ble_scale_app/widgets/dyno_data_display.dart';
import 'package:ble_scale_app/widgets/gender_toggle.dart';
import 'package:ble_scale_app/widgets/status_icon_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../models/leaderboard_entry.dart';
import '../providers/leaderboard_provider.dart';
import '../services/leaderboard_service.dart';
import '../widgets/leaderboard.dart';
import '../widgets/weight_graph.dart';
import '../screens/session_details_page.dart';
import './saved_sessions_page.dart';
import './leaderboard_page.dart';
import '../utils/number.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class ScaleHomePage extends StatefulWidget {
  @override
  _ScaleHomePageState createState() => _ScaleHomePageState();
}

class _ScaleHomePageState extends State<ScaleHomePage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  String elapsedTime = '0:00';
  Leaderboard leaderboard = Leaderboard(isPreviewMode: true);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  void initState() {
    super.initState();
    requestPermissions();
    Future.delayed(const Duration(seconds: 2), scanForDevices);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLeaderboardData();
    });
  }

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.locationWhenInUse.request();
  }

  Future<void> _fetchLeaderboardData() async {
    try {
      await Provider.of<LeaderboardProvider>(context, listen: false)
          .fetchEntries(true);
    } catch (e) {
      print("Error fetching leaderboard data: $e");
    }
  }

  void scanForDevices() {
    Provider.of<DynoDataProvider>(context, listen: false).scanForDevices();
  }

  void resetData() {
    Provider.of<DynoDataProvider>(context, listen: false).resetData();
  }

  void stopData() {
    print("Stopping data");
    Provider.of<DynoDataProvider>(context, listen: false).stopData();
  }

  void startData() {
    print("Starting data");
    Provider.of<DynoDataProvider>(context, listen: false).startData();
  }

  void viewDetails() {
    if (Provider.of<DynoDataProvider>(context, listen: false)
        .graphData
        .isNotEmpty) {
      // Show option to add to leaderboard
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SessionDetailsPage(
              graphData: Provider.of<DynoDataProvider>(context, listen: false)
                  .graphData,
              maxWeight: Provider.of<DynoDataProvider>(context, listen: false)
                          .maxWeights[
                      Provider.of<DynoDataProvider>(context, listen: false)
                          .weightUnit] ??
                  0.0,
              sessionStartTime:
                  Provider.of<DynoDataProvider>(context, listen: false)
                      .sessionStartTime,
              totalLoad: Provider.of<DynoDataProvider>(context, listen: false)
                  .totalLoad,
              averageWeight:
                  Provider.of<DynoDataProvider>(context, listen: false)
                      .averageWeight,
              elapsedTimeString: formatElapsedTime(
                  Provider.of<DynoDataProvider>(context, listen: false)
                      .stopwatch
                      .elapsed),
              elapsedTimeMs:
                  Provider.of<DynoDataProvider>(context, listen: false)
                      .stopwatch
                      .elapsedMilliseconds,
              weightUnit: Provider.of<DynoDataProvider>(context, listen: false)
                  .weightUnit,
            ),
          ));
    }
  }

  void _addToLeaderboard(BuildContext context) async {
    String name = '';
    String email = '';
    String gender = 'Male';

    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add to Leaderboard"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  ),
                  onChanged: (value) {
                    name = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  ),
                  onChanged: (value) {
                    email = value;
                  },
                ),
                const SizedBox(height: 8.0),
                GenderToggle(
                  initialGender: gender,
                  onGenderChanged: (selectedGender) {
                    gender = selectedGender;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Add"),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // Add entry to the leaderboard
                  LeaderboardService().addEntry(LeaderboardEntry(
                    name: name,
                    email: email,
                    maxWeight: Provider.of<DynoDataProvider>(context,
                                listen: false)
                            .maxWeights[
                        Provider.of<DynoDataProvider>(context, listen: false)
                            .weightUnit]!,
                    gender: gender,
                    date: DateTime.now(),
                  ));

                  // If email is provided, send the summary
                  if (email.isNotEmpty) {
                    await _sendEmailSummary(name, email);
                  }

                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendEmailSummary(String name, String email) async {
    // Create a table of graphData
    StringBuffer graphDataTable = StringBuffer();
    graphDataTable.writeln('\n\nGraph Data:');
    graphDataTable.writeln(
        'Time (s)\tWeight (${Provider.of<DynoDataProvider>(context, listen: false).weightUnit})');
    for (var spot
        in Provider.of<DynoDataProvider>(context, listen: false).graphData) {
      graphDataTable.writeln(
          '${spot.x.toStringAsFixed(2)}\t\t${spot.y.toStringAsFixed(2)}');
    }
    int maxWeight = Provider.of<DynoDataProvider>(context, listen: false)
        .maxWeights[
            Provider.of<DynoDataProvider>(context, listen: false).weightUnit]!
        .toInt();
    final String sessionData = '''
Session Time: ${DateFormat('MMM d, yyyy, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(Provider.of<DynoDataProvider>(context, listen: false).sessionStartTime))}
Max Pull: ${maxWeight.toStringAsFixed(2)} ${Provider.of<DynoDataProvider>(context, listen: false).weightUnit}
80% Pull: ${(maxWeight * 0.8).toStringAsFixed(2)} ${Provider.of<DynoDataProvider>(context, listen: false).weightUnit}
20% Pull: ${(maxWeight * 0.2).toStringAsFixed(2)} ${Provider.of<DynoDataProvider>(context, listen: false).weightUnit}
Elapsed Time: ${elapsedTime}
$graphDataTable
''';

    // Capture screenshot of the graph
    final Email emailToSend = Email(
      body: '''
Name: $name
Max Weight: ${Provider.of<DynoDataProvider>(context, listen: false).maxWeights[Provider.of<DynoDataProvider>(context, listen: false).weightUnit]!}
Elapsed Time: ${formatElapsedTime(Provider.of<DynoDataProvider>(context, listen: false).stopwatch.elapsed)}
Average Weight: ${Provider.of<DynoDataProvider>(context, listen: false).averageWeight.toStringAsFixed(1)}
Total Load: ${Provider.of<DynoDataProvider>(context, listen: false).totalLoad.toStringAsFixed(1)}

Please find attached the screenshot of the weight graph.
''',
      subject: 'Leaderboard Entry Summary',
      recipients: [email],
    );

    await FlutterEmailSender.send(emailToSend);
  }

  @override
  Widget build(BuildContext context) {
    // Get the current orientation
    Orientation orientation = MediaQuery.of(context).orientation;

    // Determine the crossAxisCount based on the orientation
    int crossAxisCount = orientation == Orientation.portrait ? 3 : 3;

    print("Inside build function");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesh'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'Session Details':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SavedSessionsPage()),
                  );
                  break;
                case 'Leaderboard':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LeaderboardPage()),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'Session Details',
                  child: Text('Session Details view'),
                ),
                PopupMenuItem<String>(
                  value: 'Leaderboard',
                  child: Text('Leaderboard view'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (orientation == Orientation.landscape) ...[
            // Row for Leaderboard and Display Cards in Portrait Mode
            Flexible(
              flex: 6,
              child: Row(
                children: [
                  DynoDataDisplay(crossAxisCount: crossAxisCount),
                  Expanded(
                    flex: 3,
                    child: FutureBuilder(
                      future: _fetchLeaderboardData(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else {
                          return leaderboard;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Vertical Layout for Landscape Mode
            Flexible(
              flex: 3,
              child: FutureBuilder(
                future: _fetchLeaderboardData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    return Leaderboard(isPreviewMode: true);
                  }
                },
              ),
            ),
            DynoDataDisplay(crossAxisCount: crossAxisCount),
          ],
          StatusIconBar(),
          Padding(
            padding: const EdgeInsets.only(
                bottom: 8.0, right: 8.0, left: 16.0, top: 0.0),
            child: WeightGraph(),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: startData,
                  child: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10), // Adjust padding
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    stopData();
                  },
                  child: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10), // Adjust padding
                  ),
                ),
                ElevatedButton(
                  onPressed: resetData,
                  child: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10), // Adjust padding
                  ),
                ),
                ElevatedButton(
                  onPressed: viewDetails,
                  child: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10), // Adjust padding
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addToLeaderboard(context);
                  },
                  child: const Text('Add to Leaderboard'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10), // Adjust padding
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
