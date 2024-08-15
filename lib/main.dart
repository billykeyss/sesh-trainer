import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

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
