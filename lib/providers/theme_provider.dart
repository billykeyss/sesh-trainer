import 'package:flutter/material.dart';
import '../models/info.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String _unit = Info.Pounds; // Default unit is kg

  ThemeMode get themeMode => _themeMode;
  String get unit => _unit;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setUnit(String unit) {
    _unit = unit;
    notifyListeners();
  }

  void toggleUnit(bool isLbs) {
    _unit = isLbs ? Info.Pounds : Info.Kilogram;
    notifyListeners();
  }

  bool get isKg => _unit == Info.Kilogram;
  bool get isLbs => _unit == Info.Pounds;
}