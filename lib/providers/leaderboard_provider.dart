import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  List<LeaderboardEntry> _maleEntries = [];
  List<LeaderboardEntry> _femaleEntries = [];
  bool _isDaily = true; // Ensure this line exists

  List<LeaderboardEntry> get maleEntries => _maleEntries;
  List<LeaderboardEntry> get femaleEntries => _femaleEntries;

  bool get isDaily => _isDaily; // Getter for external access

  Future<void> fetchEntries(bool isDaily) async {
    try {
      _isDaily = isDaily; // Update the internal state
      final maleEntries = isDaily ? await LeaderboardService().getDailyEntries('Male') : await LeaderboardService().getAllEntries('Male');
      final femaleEntries = isDaily ? await LeaderboardService().getDailyEntries('Female') : await LeaderboardService().getAllEntries('Female');

      // if (_entriesHaveChanged(maleEntries, femaleEntries)) {
        _maleEntries = maleEntries;
        _femaleEntries = femaleEntries;
        notifyListeners();
      // }
    } catch (e) {
      print("Error fetching leaderboard entries: $e");
    }
  }

  bool _entriesHaveChanged(List<LeaderboardEntry> maleEntries, List<LeaderboardEntry> femaleEntries) {
    return !ListEquality().equals(_maleEntries, maleEntries) || !ListEquality().equals(_femaleEntries, femaleEntries);
  }
}
