import 'package:drift/drift.dart'; // Import Drift for `Value`
import '../database/leaderboard_database.dart'
    as db; // Import your Drift database
import '../models/leaderboard_entry.dart' as model;

class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._internal();
  late db.LeaderboardDatabase _database;

  factory LeaderboardService() {
    return _instance;
  }

  LeaderboardService._internal() {
    _database = db.LeaderboardDatabase();
  }

  Future<void> addEntry(model.LeaderboardEntry entry) async {
    // Convert LeaderboardEntry to a companion for Drift
    final companion = db.LeaderboardEntriesCompanion(
      name: Value(entry.name),
      email: entry.email != null ? Value(entry.email) : const Value.absent(),
      maxWeight: Value(entry.maxWeight),
      gender: Value(entry.gender),
      date: Value(entry.date),
    );
    await _database.insertEntry(companion);
  }

  Future<List<model.LeaderboardEntry>> getTopEntries(String gender,
      {int limit = 3}) async {
    final entries = await _database.getTopEntries(gender, limit: limit);
    return entries
        .map((e) => model.LeaderboardEntry(
              id: e.id,
              name: e.name,
              email: e.email ?? '',
              maxWeight: e.maxWeight,
              gender: e.gender,
              date: e.date,
            ))
        .toList();
  }

  Future<List<model.LeaderboardEntry>> getAllEntries(String gender) async {
    final entries = await _database.getAllEntries(gender);
    return entries
        .map((e) => model.LeaderboardEntry(
              id: e.id,
              name: e.name,
              email: e.email ?? '',
              maxWeight: e.maxWeight,
              gender: e.gender,
              date: e.date,
            ))
        .toList();
  }

  Future<List<model.LeaderboardEntry>> getDailyEntries(String gender) async {
    final entries = await _database.getDailyEntries(gender);
    return entries
        .map((e) => model.LeaderboardEntry(
              id: e.id,
              name: e.name,
              email: e.email ?? '',
              maxWeight: e.maxWeight,
              gender: e.gender,
              date: e.date,
            ))
        .toList();
  }
}
