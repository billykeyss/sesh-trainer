import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  List<LeaderboardEntry> _maleEntries = [];
  List<LeaderboardEntry> _femaleEntries = [];
  bool _isDaily = true;

  List<LeaderboardEntry> get maleEntries => _maleEntries;
  List<LeaderboardEntry> get femaleEntries => _femaleEntries;
  bool get isDaily => _isDaily;

  Future<void> fetchEntries(bool isDaily) async {
    try {
      _isDaily = isDaily; // Update the internal state
      final maleEntries = await _fetchEntries('Male', isDaily);
      final femaleEntries = await _fetchEntries('Female', isDaily);

      if (_entriesHaveChanged(maleEntries, femaleEntries)) {
        _maleEntries = maleEntries;
        _femaleEntries = femaleEntries;
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching leaderboard entries: $e");
    }
  }

  Future<List<LeaderboardEntry>> _fetchEntries(String gender, bool isDaily) async {
    return isDaily
        ? await LeaderboardService().getDailyEntries(gender)
        : await LeaderboardService().getAllEntries(gender);
  }

  bool _entriesHaveChanged(List<LeaderboardEntry> maleEntries, List<LeaderboardEntry> femaleEntries) {
    return !ListEquality().equals(_maleEntries, maleEntries) || !ListEquality().equals(_femaleEntries, femaleEntries);
  }
}
