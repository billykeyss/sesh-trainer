import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
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
  double maxWeight = 0;
  double averageWeight = 0.0;
  List<FlSpot> graphData = [];
  List<double> weightRecords = [];
  bool recordData = false;
  int lastUpdateTime = 0;
  String weightUnit = "kg";

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
    print("Starting scan for devices");
    startScan((ResJson res) {
      if (res.code == 1) {
        setState(() {
          if (recordData) {
            print(res.data);
            weight = max(res.data.weight / -100.0, 0.0);
            connectedDevice = res.data.device;
            weightUnit = res.data.getUnitString();
            updateGraphData(weight!);
            maxWeight = max(maxWeight, weight ?? maxWeight);
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
        if (currentTime - lastUpdateTime> 1000) {
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
      maxWeight = 0.0;
    });
  }

  void stopData() {
    setState(() {
      recordData = false;
    });
  }

  void startData() {
    setState(() {
      recordData = true;
    });
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
                    value: (weight != null ? weight!.toStringAsFixed(1) : '0.0') + " " + weightUnit,
                    unit: ''),
                DisplayCard(
                    title: 'Max', value: maxWeight.toStringAsFixed(1), unit: ''),
                DisplayCard(
                    title: 'Average',
                    value: averageWeight.toString(),
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
