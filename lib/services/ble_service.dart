import 'package:flutter_blue/flutter_blue.dart';
import '../models/info.dart';
import '../models/res_json.dart';

typedef Callback = void Function(ResJson res);

class LeScanCallback {
  final Callback callback;

  LeScanCallback(this.callback);

  void onScanResult(ScanResult scanResult) {
    final name = scanResult.device.name;
    final scanRecord = scanResult.advertisementData;

    if (name == 'IF_B7') {
      final mu = scanRecord.manufacturerData[256];
      if (mu == null) return;

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
