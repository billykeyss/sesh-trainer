import 'package:fl_chart/fl_chart.dart';

double roundToNearest10(double value) {
  return (value / 10).round() * 10.0;
}

String formatElapsedTime(Duration duration) {
  int minutes = duration.inMinutes;
  int seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
}

// Function to format elapsed time in milliseconds to mm:ss
String formatElapsedTimeIntToString(int elapsedTimeMs) {
  int totalSeconds = (elapsedTimeMs / 1000).floor(); // Convert ms to seconds
  int minutes = totalSeconds ~/ 60; // Calculate minutes
  int seconds = totalSeconds % 60; // Calculate remaining seconds
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

double calculateMaxWeight(List<FlSpot> graphData) {
  return graphData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
}

double calculateAverageWeight(List<FlSpot> graphData) {
  List<double> weights = graphData.map((spot) => spot.y).toList();
  if (weights.isEmpty) return 0.0;
  return weights.reduce((a, b) => a + b) / weights.length;
}

double calculateTotalLoad(List<FlSpot> graphData) {
  return graphData.fold(0.0, (total, spot) => total + spot.y);
}
