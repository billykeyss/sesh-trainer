import 'package:ble_scale_app/providers/dyno_data_provider.dart';
import 'package:ble_scale_app/widgets/dyno_data_display.dart';
import 'package:ble_scale_app/widgets/gender_toggle.dart';
import 'package:ble_scale_app/widgets/status_icon_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../models/leaderboard_entry.dart';
import '../models/info.dart';
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
import 'dart:math';
import '../utils/email_utils.dart';

class ScaleHomePage extends StatefulWidget {
  @override
  _ScaleHomePageState createState() => _ScaleHomePageState();
}

class _ScaleHomePageState extends State<ScaleHomePage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  String elapsedTime = '0:00';
  bool showTestButton = true; // Feature gate for the test button
  bool showLeaderboard = true; // Feature flag for the leaderboard

  Leaderboard leaderboard = Leaderboard(isPreviewMode: true);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  void initState() {
    super.initState();
    requestPermissions();
    Future.delayed(const Duration(seconds: 2), scanForDevices);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (showLeaderboard) {
        // Only fetch data if leaderboard is enabled
        _fetchLeaderboardData();
      }
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
    final dynoDataProvider =
        Provider.of<DynoDataProvider>(context, listen: false);

    if (dynoDataProvider.graphData.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionDetailsPage(
            graphData: dynoDataProvider.graphData,
            sessionStartTime: DateTime.fromMillisecondsSinceEpoch(
                dynoDataProvider.sessionStartTime),
            elapsedTimeMs: dynoDataProvider.stopwatch.elapsedMilliseconds,
            weightUnit: dynoDataProvider.weightUnit,
            sessionName:
                'Session ${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}', // Example session name
          ),
        ),
      );
    }
  }

  void _addToLeaderboard(BuildContext context) async {
    String name = '';
    String email = '';
    String gender = 'Male';

    final _formKey = GlobalKey<FormState>();
    final dynoDataProvider =
        Provider.of<DynoDataProvider>(context, listen: false);

    if (dynoDataProvider.graphData.isNotEmpty) {
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
                    final sessionStartTime =
                        DateTime.fromMillisecondsSinceEpoch(
                            dynoDataProvider.sessionStartTime);
                    final graphData = dynoDataProvider.graphData
                        .map((spot) => {'x': spot.x, 'y': spot.y})
                        .toList();
                    final maxWeight = dynoDataProvider
                            .maxWeights[dynoDataProvider.weightUnit] ??
                        0.0;
                    final weightUnit = dynoDataProvider.weightUnit;
                    final elapsedTime =
                        dynoDataProvider.stopwatch.elapsed.toString();
                    final averageWeight = dynoDataProvider.averageWeight;
                    final totalLoad = dynoDataProvider.totalLoad;

                    // Add entry to the leaderboard
                    LeaderboardService().addEntry(LeaderboardEntry(
                      name: name,
                      email: email,
                      maxWeight: maxWeight,
                      gender: gender,
                      date: DateTime.now(),
                    ));

                    // Send the email if an email address was provided
                    if (email.isNotEmpty) {
                      await sendEmailSummary(
                        name,
                        email,
                        sessionStartTime,
                        graphData,
                        maxWeight,
                        weightUnit,
                        elapsedTime,
                        averageWeight,
                        totalLoad,
                      );
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
  }

  void _runTestSession() {
    final dynoDataProvider =
        Provider.of<DynoDataProvider>(context, listen: false);

    dynoDataProvider.resetData();
    dynoDataProvider.startData();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timer.tick <= 5) {
        double randomWeight = 50 + Random().nextDouble() * 100;
        Info testInfo = Info(
          weight: randomWeight.toInt(),
          unit:
              Info.WEIGHT_KGS, // Use either Info.WEIGHT_KGS or Info.WEIGHT_LBS
          name: 'Test',
          device: null,
        );
        dynoDataProvider.updateGraphData(testInfo);
      } else {
        dynoDataProvider.stopData();
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;

    int crossAxisCount = orientation == Orientation.portrait ? 3 : 3;

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
                  if (showLeaderboard) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LeaderboardPage()),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              List<PopupMenuEntry<String>> menuItems = [
                PopupMenuItem<String>(
                  value: 'Session Details',
                  child: Text('Session Details view'),
                ),
              ];
              if (showLeaderboard) {
                menuItems.add(
                  PopupMenuItem<String>(
                    value: 'Leaderboard',
                    child: Text('Leaderboard view'),
                  ),
                );
              }
              return menuItems;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (orientation == Orientation.landscape) ...[
            Flexible(
              flex: 6,
              child: Row(
                children: [
                  DynoDataDisplay(crossAxisCount: crossAxisCount),
                  if (showLeaderboard)
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
            if (showLeaderboard)
              Flexible(
                flex: 4,
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
            padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: startData,
                  child: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    stopData();
                  },
                  child: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                ),
                ElevatedButton(
                  onPressed: resetData,
                  child: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                ),
                if (showTestButton) // Feature gate for the test button
                  ElevatedButton(
                    onPressed: _runTestSession,
                    child: const Text('Test'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                    ),
                  ),
              ],
            ),
          ),
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
                  onPressed: viewDetails,
                  child: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                ),
                if (showLeaderboard)
                  ElevatedButton(
                    onPressed: () {
                      _addToLeaderboard(context);
                    },
                    child: const Text('Add to Leaderboard'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
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
