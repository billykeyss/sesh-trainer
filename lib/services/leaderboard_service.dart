import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._internal();
  Database? _database;

  factory LeaderboardService() {
    return _instance;
  }

  LeaderboardService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'leaderboard.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      '''
      CREATE TABLE leaderboard(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        maxWeight REAL,
        gender TEXT,
        date TEXT
      )
      ''',
    );
  }

  Future<void> addEntry(LeaderboardEntry entry) async {
    final db = await database;
    await db.insert(
      'leaderboard',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LeaderboardEntry>> getTopEntries(String gender,
      {int limit = 3}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'leaderboard',
      where: 'gender = ?',
      whereArgs: [gender],
      orderBy: 'maxWeight DESC',
      limit: limit,
    );

    print(maps);
    return List.generate(maps.length, (i) {
      return LeaderboardEntry.fromMap(maps[i]);
    });
  }

  Future<List<LeaderboardEntry>> getAllEntries(String gender) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'leaderboard',
      where: 'gender = ?',
      whereArgs: [gender],
    );
    return List.generate(maps.length, (i) {
      return LeaderboardEntry.fromMap(maps[i]);
    });
  }

  Future<List<LeaderboardEntry>> getDailyEntries(String gender) async {
    final db = await database;
    DateTime today = DateTime.now();
    final List<Map<String, dynamic>> maps = await db.query(
      'leaderboard',
      where: 'gender = ? AND date(date) = date(?)',
      whereArgs: [gender, today.toIso8601String()],
    );
    return List.generate(maps.length, (i) {
      return LeaderboardEntry.fromMap(maps[i]);
    });
  }
}


// import '../models/leaderboard_entry.dart';
// import '../database/leaderboard_database.dart'; // Import your Drift database

// class LeaderboardService {
//   static final LeaderboardService _instance = LeaderboardService._internal();
//   late LeaderboardDatabase _database;

//   factory LeaderboardService() {
//     return _instance;
//   }

//   LeaderboardService._internal() {
//     _database = LeaderboardDatabase();
//   }

//   Future<void> addEntry(LeaderboardEntry entry) async {
//     await _database.insertEntry(entry);
//   }

//   Future<List<LeaderboardEntry>> getTopEntries(String gender, {int limit = 3}) async {
//     return await _database.getTopEntries(gender, limit: limit);
//   }

//   Future<List<LeaderboardEntry>> getAllEntries(String gender) async {
//     return await _database.getAllEntries(gender);
//   }

//   Future<List<LeaderboardEntry>> getDailyEntries(String gender) async {
//     return await _database.getDailyEntries(gender);
//   }
// }
