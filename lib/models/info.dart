import 'package:flutter_blue/flutter_blue.dart';

class Info {
  static const int WEIGHT_LBS = 0;
  static const int WEIGHT_KGS = 1;
  static const String Pounds = "lbs";
  static const String Kilogram = "kg";

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

  @override
  String toString() {
    return 'Info(weight: $weight, unit: $unit, name: $name, device: ${device.id})';
  }

  String getUnitString() {
    if (unit == WEIGHT_KGS) {
      return Kilogram;
    }
    return Pounds;
  }
}
