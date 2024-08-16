import 'package:ble_scale_app/models/info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'dart:async';
import '../models/res_json.dart';
import '../services/ble_service.dart';
import '../widgets/display_card.dart';
import '../widgets/weight_graph.dart';
import './session_details_page.dart';
import 'package:fl_chart/fl_chart.dart';

class ScaleHomePage extends StatefulWidget {
  @override
  _ScaleHomePageState createState() => _ScaleHomePageState();
}

class _ScaleHomePageState extends State<ScaleHomePage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  double? weight;
  Map<String, double> maxWeights = {
    Info.Kilogram: 0.0,
    Info.Pounds: 0.0
  }; // Map to store max weights
  double averageWeight = 0.0;
  double totalLoad = 0.0; // Variable to store the Area Under the Curve (AUC)
  List<FlSpot> graphData = [];
  List<double> weightRecords = [];
  bool recordData = false;
  int lastDataReceivedTime = 0;
  int lastUpdateTime = 0;
  int sessionStartTime = 0;
  String weightUnit = Info.Kilogram;
  Stopwatch stopwatch = Stopwatch(); // Stopwatch to track elapsed time
  String elapsedTime = '0:00';
  Timer? timer;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    Future.delayed(const Duration(seconds: 2), scanForDevices);
  }

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.locationWhenInUse.request();
  }

  void scanForDevices() {
    startScan((ResJson res) {
      if (res.code == 1) {
        setState(() {
          lastDataReceivedTime = DateTime.now().millisecondsSinceEpoch;
          weight = max(res.data.weight / -100.0, 0.0);
          weightUnit = res.data.getUnitString();
          if (recordData) {
            connectedDevice = res.data.device;
            updateGraphData(weight!);

            // Update max weight based on unit
            if (weightUnit == Info.Kilogram || weightUnit == Info.Pounds) {
              maxWeights[weightUnit] = max(
                  maxWeights[weightUnit]!, weight ?? maxWeights[weightUnit]!);
            }
          }
        });
      } else {
        print('Scan failed: ${res.msg}');
      }
    });
  }

  void updateGraphData(double newWeight) {
    setState(() {
      if (recordData) {
        int currentTime = DateTime.now().millisecondsSinceEpoch;

        double elapsedTimeInSeconds = stopwatch.elapsedMilliseconds / 1000.0;
        graphData.add(FlSpot(elapsedTimeInSeconds, newWeight));

        if (graphData.isNotEmpty) {
          int timeDelta = currentTime - lastUpdateTime;

          // Calculate the area under the curve (AUC) using the trapezoidal rule
          double previousWeight = graphData.last.y;
          double area =
              ((previousWeight + newWeight) * 9.81 / 2) * (timeDelta / 1000.0);
          totalLoad += area;
        }

        if (newWeight > 0) {
          weightRecords.add(newWeight);
        }

        averageWeight = weightRecords.isNotEmpty
            ? double.parse(
                (weightRecords.reduce((a, b) => a + b) / weightRecords.length)
                    .toStringAsFixed(1))
            : 0.0;
        lastUpdateTime = currentTime;
      }
    });
  }

  void resetData() {
    setState(() {
      weight = null;
      recordData = false;
      graphData.clear();
      weightRecords.clear();
      averageWeight = 0.0;
      totalLoad = 0.0;
      sessionStartTime = 0;
      maxWeights = {Info.Kilogram: 0.0, Info.Pounds: 0.0};
      stopwatch.reset();
    });
  }

  void stopData() {
    setState(() {
      recordData = false;
      stopwatch.stop();
      timer?.cancel();
      print(graphData);
      viewDetails();
    });
  }

  void startData() {
    setState(() {
      recordData = true;
      stopwatch.start();
      sessionStartTime = DateTime.now().millisecondsSinceEpoch;
      timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        if (!recordData) {
          timer.cancel();
        }
        setState(() {}); // Trigger a rebuild to update the stopwatch display
      });
    });
  }

  void viewDetails() {
    if (graphData.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Session Stopped"),
            content: const Text("Would you like to view the session details?"),
            actions: <Widget>[
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("View Details"),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SessionDetailsPage(
                        graphData: graphData,
                        maxWeight: maxWeights[weightUnit] ?? 0.0,
                        sessionStartTime: sessionStartTime,
                        totalLoad: totalLoad,
                        averageWeight: averageWeight,
                        elapsedTimeString: formatElapsedTime(stopwatch.elapsed),
                        elapsedTimeMs: stopwatch.elapsedMilliseconds,
                        weightUnit: weightUnit,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }

  String formatElapsedTime(Duration duration) {
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesh'),
      ),
      body: Column(
        children: [
          Flexible(
            flex: 8, // Adjust this flex value based on your needs
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1,
              padding: const EdgeInsets.all(1.0),
              children: [
                DisplayCard(
                    title: 'Weight',
                    value: '${weight?.toStringAsFixed(1) ?? '0.0'}',
                    unit: weightUnit),
                DisplayCard(
                    title: 'Max',
                    value:
                        '${maxWeights[weightUnit]?.toStringAsFixed(1) ?? '0.0'}',
                    unit: weightUnit),
                DisplayCard(
                    title: 'Average',
                    value: '$averageWeight',
                    unit: weightUnit),
                DisplayCard(
                    title: 'Elapsed Time',
                    value: formatElapsedTime(stopwatch.elapsed),
                    unit: ''),
                DisplayCard(
                    title: 'Total Load (AUC)',
                    value: '${totalLoad.toStringAsFixed(2)}',
                    unit: '$weightUnit*s'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              DateTime.now().millisecondsSinceEpoch - lastDataReceivedTime <
                      100000
                  ? 'Device Connected'
                  : 'Device Not Connected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DateTime.now().millisecondsSinceEpoch -
                            lastDataReceivedTime <
                        100000
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
          // Indicator text for recordData
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              recordData ? 'Recording Data' : 'Not Recording Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: recordData ? Colors.green : Colors.red,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                bottom: 8.0, right: 8.0, left: 16.0, top: 0.0),
            child: WeightGraph(graphData: graphData),
          ),
          // Row to place buttons side by side
          Padding(
            padding:
                const EdgeInsets.only(bottom: 24.0), // Larger bottom padding
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly, // Adjust spacing
              children: [
                ElevatedButton(
                  onPressed: startData,
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (recordData) {
                      stopData();
                    } else {
                      viewDetails();
                    }
                  },
                  child: Text(recordData ? 'Stop' : 'View Details'),
                ),
                ElevatedButton(
                  onPressed: resetData,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
