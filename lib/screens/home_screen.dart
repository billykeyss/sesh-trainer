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
  List<FlSpot> graphData = [];
  List<double> weightRecords = [];
  bool recordData = false;
  int lastUpdateTime = 0;
  String weightUnit = Info.Kilogram;
  Stopwatch stopwatch = Stopwatch(); // Stopwatch to track elapsed time
  String elapsedTime = '0:00';
  Timer? timer;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    scanForDevices();
  }

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.locationWhenInUse.request();
  }

  void scanForDevices() {
    startScan((ResJson res) {
      if (res.code == 1) {
        setState(() {
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
        if (currentTime - lastUpdateTime > 250) {
          graphData.add(FlSpot(graphData.length.toDouble(), newWeight));
          lastUpdateTime = currentTime;
        }
        if (newWeight > 0) {
          weightRecords.add(newWeight);
        }
        averageWeight = weightRecords.isNotEmpty
            ? double.parse(
                (weightRecords.reduce((a, b) => a + b) / weightRecords.length)
                    .toStringAsFixed(1))
            : 0.0;
      }
    });
  }

  void resetData() {
    setState(() {
      weight = null;
      graphData.clear();
      weightRecords.clear();
      averageWeight = 0.0;
      maxWeights = {
        Info.Kilogram: 0.0,
        Info.Pounds: 0.0
      }; // Reset max weights map
      stopwatch.reset();
    });
  }

  void stopData() {
    setState(() {
      recordData = false;
      stopwatch.stop();
      timer?.cancel();
    });
  }

  void startData() {
    setState(() {
      recordData = true;
      stopwatch.start();
      timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        if (!recordData) {
          timer.cancel();
        }
        setState(() {}); // Trigger a rebuild to update the stopwatch display
      });
    });
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
            flex: 12, // Adjust this flex value based on your needs
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1,
              padding: const EdgeInsets.all(8.0),
              children: [
                DisplayCard(
                    title: 'Weight',
                    value: '${weight?.toStringAsFixed(1) ?? '0.0'} $weightUnit',
                    unit: ''),
                DisplayCard(
                    title: 'Max',
                    value:
                        '${maxWeights[weightUnit]?.toStringAsFixed(1) ?? '0.0'} $weightUnit',
                    unit: ''),
                DisplayCard(
                    title: 'Average', value: '$averageWeight', unit: ''),
                DisplayCard(
                    title: 'Elapsed Time',
                    value: formatElapsedTime(stopwatch.elapsed),
                    unit: ''),
              ],
            ),
          ),
          // Indicator text for recordData
          Padding(
            padding: const EdgeInsets.all(16.0),
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
            padding: const EdgeInsets.all(8.0),
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
                  onPressed: stopData,
                  child: const Text('Stop'),
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
