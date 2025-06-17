import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/info.dart';
import '../services/ble_service.dart';
import '../database/session_database.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import 'package:intl/intl.dart';

class DynoDataProvider with ChangeNotifier {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  double? weight;
  Map<String, double> maxWeights = {Info.Kilogram: 0.0, Info.Pounds: 0.0};
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
  late final SessionDatabase _database;
  bool _isScanning = false;

  // Callback for session auto-save notifications
  Function(String sessionName)? onSessionAutoSaved;

  DynoDataProvider() {
    _database = SessionDatabase();
  }

  double get totalLoad => _totalLoad;

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.locationWhenInUse.request();
  }

  void scanForDevices() {
    if (_isScanning) return; // Prevent duplicate scans
    _isScanning = true;

    startScan((res) {
      if (res.code == 1) {
        updateGraphData(res.data);
      } else {
        print('Scan failed: ${res.msg}');
      }
    });
  }

  void updateGraphData(Info data) {
    lastDataReceivedTime = DateTime.now().millisecondsSinceEpoch;
    connectedDevice = data.device;
    double newWeight = data.weight.toDouble();
    weight = newWeight;
    weightUnit = data.getUnitString();
    if (recordData) {
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      double elapsedTimeInSeconds = stopwatch.elapsedMilliseconds / 1000.0;
      graphData.add(FlSpot(elapsedTimeInSeconds, newWeight));

      if (graphData.isNotEmpty) {
        int timeDelta = currentTime - lastUpdateTime;
        double previousWeight = graphData.last.y;
        double area = ((previousWeight + newWeight) / 2) * (timeDelta / 1000.0);
        _totalLoad += area;
      }

      if (newWeight > 0) {
        weightRecords.add(newWeight);
      }

      if (weightUnit == Info.Kilogram || weightUnit == Info.Pounds) {
        maxWeights[weightUnit] =
            max(maxWeights[weightUnit]!, weight ?? maxWeights[weightUnit]!);
      }

      averageWeight = weightRecords.isNotEmpty
          ? double.parse(
              (weightRecords.reduce((a, b) => a + b) / weightRecords.length)
                  .toStringAsFixed(1))
          : 0.0;
      lastUpdateTime = currentTime;
    }
    notifyListeners();
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

    // Auto-save session if there's meaningful data
    _autoSaveSession();

    notifyListeners();
  }

  Future<void> _autoSaveSession() async {
    // Only save if session has meaningful data (at least 5 seconds and some weight data)
    if (graphData.isNotEmpty &&
        stopwatch.elapsedMilliseconds >= 5000 &&
        maxWeights.values.any((weight) => weight > 0)) {
      try {
        // Generate session name with timestamp
        final sessionTime =
            DateTime.fromMillisecondsSinceEpoch(sessionStartTime);
        final sessionName =
            'Session ${DateFormat('MMM dd, yyyy HH:mm').format(sessionTime)}';

        // Check if session with this name already exists
        final existingSessions = await _database.getAllSessions();
        final sessionExists =
            existingSessions.any((session) => session.name == sessionName);

        if (!sessionExists) {
          final newSession = SessionsCompanion(
            name: drift.Value(sessionName),
            email: drift.Value(''), // Keep empty for personal training
            elapsedTimeMs: drift.Value(stopwatch.elapsedMilliseconds),
            weightUnit: drift.Value(weightUnit),
            sessionTime: drift.Value(sessionTime),
            graphData: drift.Value(jsonEncode(
                graphData.map((spot) => {'x': spot.x, 'y': spot.y}).toList())),
            data: drift.Value(''),
          );

          await _database.insertSession(newSession);
          print('Session auto-saved: $sessionName');

          // Notify UI about successful auto-save
          onSessionAutoSaved?.call(sessionName);
        }
      } catch (e) {
        print('Error auto-saving session: $e');
      }
    }
  }

  // Call this to stop scanning safely
  void stopScanning() async {
    if (_isScanning) {
      stopScan();
      _isScanning = false;
    }
  }
}
