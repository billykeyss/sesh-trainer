double roundToNearest10(double value) {
  return (value / 10).round() * 10.0;
}

String formatElapsedTime(Duration duration) {
  int minutes = duration.inMinutes;
  int seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
}

// Function to format elapsed time in milliseconds to mm:ss
String formatElapsedTimeToString(int elapsedTimeMs) {
  int totalSeconds = (elapsedTimeMs / 1000).floor(); // Convert ms to seconds
  int minutes = totalSeconds ~/ 60; // Calculate minutes
  int seconds = totalSeconds % 60; // Calculate remaining seconds
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
