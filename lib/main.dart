import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(BLEScaleApp());

class BLEScaleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Scale App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ScaleHomePage(),
    );
  }
}

class ScaleHomePage extends StatefulWidget {
  @override
  _ScaleHomePageState createState() => _ScaleHomePageState();
}

class _ScaleHomePageState extends State<ScaleHomePage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  double? weight;

  @override
  void initState() {
    super.initState();
    scanForDevices();
  }

  void scanForDevices() {
    startScan((ResJson res) {
      if (res.code == 1) {
        setState(() {
          weight = res.data.weight / 10.0; // Assuming weight is in grams
          connectedDevice = res.data.device; // Use the device from scan result
        });
      } else {
        print('Scan failed: ${res.msg}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BLE Scale App'),
      ),
      body: Center(
        child: connectedDevice == null
            ? Text('Scanning for devices...')
            : weight == null
                ? Text('Connected to ${connectedDevice!.name}, waiting for data...')
                : Text('Weight: ${weight!.toStringAsFixed(1)} kg'),
      ),
    );
  }
}

// Data classes and BLE scanning logic
class ResJson {
  final int code;
  final String msg;
  final Info data;

  ResJson({required this.code, required this.msg, required this.data});
}

class Info {
  final int weight;
  final int unit;
  final String name;
  final BluetoothDevice device;

  Info({
    required this.weight,
    required this.unit,
    required this.name,
    required this.device,
  });
}

typedef Callback = void Function(ResJson res);

class LeScanCallback {
  final Callback callback;

  LeScanCallback(this.callback);

  void onScanResult(ScanResult scanResult) {
    final name = scanResult.device.name;
    final scanRecord = scanResult.advertisementData;

    if (name == 'IF_B7') {
      final mu = scanRecord.manufacturerData[256];
      if (mu == null) {
        return;
      }
      int weight = ((mu[10] & 0xff) << 8) | (mu[11] & 0xff);
      final plus = mu[12];
      if (plus != 0) {
        weight = -weight;
      }
      final unit = mu[14] & 0x0f;
      final data = Info(
        weight: weight,
        unit: unit,
        name: 'IF_B7',
        device: scanResult.device,
      );
      final resJson = ResJson(code: 1, msg: 'success', data: data);
      callback(resJson);
    }
  }
}

void startScan(Callback callback) async {
  final FlutterBlue flutterBlue = FlutterBlue.instance;

  flutterBlue.scanResults.listen((results) {
    for (ScanResult result in results) {
      LeScanCallback(callback).onScanResult(result);
    }
  });

  flutterBlue.startScan(scanMode: ScanMode.lowLatency);
}

void stopScan() async {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  await flutterBlue.stopScan();
}
