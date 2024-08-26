double roundToNearest10(double value) {
  return (value / 10).round() * 10.0;
}

  String formatElapsedTime(Duration duration) {
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }