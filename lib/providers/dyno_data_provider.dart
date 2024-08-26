import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/info.dart';
import '../services/ble_service.dart';

class DynoDataProvider with ChangeNotifier {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  double? weight;
  Map<String, double> maxWeights = {
    Info.Kilogram: 0.0,
    Info.Pounds: 0.0
  };
  double averageWeight = 0.0;
  double _totalLoad = 0.0;
  List<FlSpot> graphData = [];
  List<double> weightRecords = [];
  bool recordData = false;
  int lastDataReceivedTime = 0;
  int lastUpdateTime = 0;
  int sessionStartTime = 0;
  String weightUnit = Info.Kilogram;
  Stopwatch stopwatch = Stopwatch();
  Timer? timer;

  double get totalLoad => _totalLoad;

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.locationWhenInUse.request();
  }

  void scanForDevices() {
    startScan((res) {
      if (res.code == 1) {
        lastDataReceivedTime = DateTime.now().millisecondsSinceEpoch;
        weight = max(res.data.weight / -100.0, 0.0);
        weightUnit = res.data.getUnitString();
        if (recordData) {
          connectedDevice = res.data.device;
          updateGraphData(weight!);

          if (weightUnit == Info.Kilogram || weightUnit == Info.Pounds) {
            maxWeights[weightUnit] = max(
                maxWeights[weightUnit]!, weight ?? maxWeights[weightUnit]!);
          }
        }
        notifyListeners();
      } else {
        print('Scan failed: ${res.msg}');
      }
    });
  }

  void updateGraphData(double newWeight) {
    if (recordData) {
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      double elapsedTimeInSeconds = stopwatch.elapsedMilliseconds / 1000.0;
      graphData.add(FlSpot(elapsedTimeInSeconds, newWeight));

      if (graphData.isNotEmpty) {
        int timeDelta = currentTime - lastUpdateTime;
        double previousWeight = graphData.last.y;
        double area =
            ((previousWeight + newWeight) / 2) * (timeDelta / 1000.0);
        _totalLoad += area;
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
      notifyListeners();
    }
  }

  void resetData() {
    weight = null;
    recordData = false;
    graphData.clear();
    weightRecords.clear();
    averageWeight = 0.0;
    _totalLoad = 0.0;
    sessionStartTime = 0;
    maxWeights = {Info.Kilogram: 0.0, Info.Pounds: 0.0};
    stopwatch.stop();
    stopwatch.reset();
    notifyListeners();
  }

  void startData() {
    recordData = true;
    stopwatch.start();
    sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!recordData) {
        timer.cancel();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void stopData() {
    recordData = false;
    stopwatch.stop();
    timer?.cancel();
    notifyListeners();
  }
}
