import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

part 'leaderboard_database.g.dart';

// Define the table
class LeaderboardEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get email => text().nullable()();
  RealColumn get maxWeight => real()();
  TextColumn get gender => text().withLength(min: 1, max: 10)();
  DateTimeColumn get date => dateTime()();
}

// Database class
@DriftDatabase(tables: [LeaderboardEntries])
class LeaderboardDatabase extends _$LeaderboardDatabase {
  LeaderboardDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Insert a leaderboard entry
  Future<int> insertEntry(LeaderboardEntriesCompanion entry) => into(leaderboardEntries).insert(entry);

  // Get top entries
  Future<List<LeaderboardEntry>> getTopEntries(String gender, {int limit = 3}) {
    return (select(leaderboardEntries)
          ..where((entry) => entry.gender.equals(gender))
          ..orderBy([(t) => OrderingTerm(expression: t.maxWeight, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
  }

  // Get all entries
  Future<List<LeaderboardEntry>> getAllEntries(String gender) {
    return (select(leaderboardEntries)..where((entry) => entry.gender.equals(gender))).get();
  }

  // Get daily entries
  Future<List<LeaderboardEntry>> getDailyEntries(String gender) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return (select(leaderboardEntries)
          ..where((entry) => entry.gender.equals(gender))
          ..where((entry) => entry.date.isBetweenValues(todayStart, todayStart.add(Duration(days: 1)))))
        .get();
  }
}

// Use SqfliteQueryExecutor instead of NativeDatabase or FlutterQueryExecutor
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(join(dbFolder.path, 'leaderboard.sqlite'));
    return SqfliteQueryExecutor.inDatabaseFolder(path: file.path);
  });
}
