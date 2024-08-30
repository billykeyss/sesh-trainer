import 'package:ble_scale_app/providers/dyno_data_provider.dart';
import 'package:ble_scale_app/widgets/dyno_data_display.dart';
import 'package:ble_scale_app/widgets/gender_toggle.dart';
import 'package:ble_scale_app/widgets/status_icon_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:ble_scale_app/models/leaderboard_entry.dart';
import 'package:ble_scale_app/models/info.dart';
import 'package:ble_scale_app/providers/leaderboard_provider.dart';
import 'package:ble_scale_app/providers/theme_provider.dart';
import 'package:ble_scale_app/services/leaderboard_service.dart';
import 'package:ble_scale_app/widgets/leaderboard.dart';
import 'package:ble_scale_app/widgets/weight_graph.dart';
import 'package:ble_scale_app/screens/session_details_page.dart';
import 'package:ble_scale_app/screens/saved_sessions_page.dart';
import 'package:ble_scale_app/screens/insights_page.dart';
import 'package:ble_scale_app/screens/leaderboard_page.dart';
import 'package:ble_scale_app/utils/number.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'dart:math';
import 'package:ble_scale_app/utils/email_utils.dart';
import 'package:fl_chart/fl_chart.dart';

class ScaleHomePage extends StatefulWidget {
  @override
  _ScaleHomePageState createState() => _ScaleHomePageState();
}

class _ScaleHomePageState extends State<ScaleHomePage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  String elapsedTime = '0:00';
  bool showTestButton = false; // Feature gate for the test button
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
    final unit = Provider.of<ThemeProvider>(context, listen: false).unit;

    if (dynoDataProvider.graphData.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionDetailsPage(
            graphData: dynoDataProvider.graphData,
            sessionStartTime: DateTime.fromMillisecondsSinceEpoch(
                dynoDataProvider.sessionStartTime),
            elapsedTimeMs: dynoDataProvider.stopwatch.elapsedMilliseconds,
            weightUnit: unit, // Use the selected unit
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
    final unit = Provider.of<ThemeProvider>(context, listen: false).unit;

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
                    double maxWeight = dynoDataProvider
                            .maxWeights[dynoDataProvider.weightUnit] ??
                        0.0;
                    if (unit == Info.Pounds &&
                        dynoDataProvider.weightUnit == Info.Kilogram) {
                      maxWeight = convertKgToLbs(maxWeight);
                    }
                    final elapsedTime =
                        dynoDataProvider.stopwatch.elapsed.toString();
                    final averageWeight = unit == Info.Pounds
                        ? convertKgToLbs(dynoDataProvider.averageWeight)
                        : dynoDataProvider.averageWeight;
                    final totalLoad = unit == Info.Pounds
                        ? convertKgToLbs(dynoDataProvider.totalLoad)
                        : dynoDataProvider.totalLoad;

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
                        unit,
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
          weight: randomWeight,
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedUnit = themeProvider.unit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesh'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Sesh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.view_list),
              title: Text('Session Details'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SavedSessionsPage(),
                  ),
                );
              },
            ),
            if (showLeaderboard)
              ListTile(
                leading: Icon(Icons.leaderboard),
                title: Text('Leaderboard'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeaderboardPage(),
                    ),
                  );
                },
              ),
            ListTile(
              leading: Icon(Icons.insights),
              title: Text('Insights'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InsightsPage(),
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.brightness_6),
              title: Text('Night Mode'),
              trailing: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                  );
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.swap_horiz),
              title: Text('Unit: $selectedUnit'),
              trailing: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Switch(
                    value: selectedUnit == Info.Pounds,
                    onChanged: (bool value) {
                      themeProvider.toggleUnit(value);
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
          ],
          Padding(
            padding: const EdgeInsets.only(
                bottom: 8.0, right: 8.0, left: 16.0, top: 0.0),
            child: Consumer<DynoDataProvider>(
              builder: (context, dynoDataProvider, child) {
                final graphData = dynoDataProvider.graphData.map((spot) {
                  double convertedWeight = spot.y;
                  if (selectedUnit == Info.Pounds &&
                      dynoDataProvider.weightUnit == Info.Kilogram) {
                    convertedWeight = convertKgToLbs(spot.y);
                  } else if (selectedUnit == Info.Kilogram &&
                      dynoDataProvider.weightUnit == Info.Pounds) {
                    convertedWeight = convertLbsToKg(spot.y);
                  }
                  return FlSpot(spot.x, convertedWeight);
                }).toList();
                return WeightGraph(
                  graphData: graphData,
                  weightUnit: selectedUnit,
                );
              },
            ),
          ),
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
                ElevatedButton(
                  onPressed: viewDetails,
                  child: const Text('View Details'),
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
          if (showLeaderboard)
            Padding(
              padding: const EdgeInsets.only(bottom: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
          DynoDataDisplay(crossAxisCount: crossAxisCount),
          StatusIconBar(),
        ],
      ),
    );
  }
}
