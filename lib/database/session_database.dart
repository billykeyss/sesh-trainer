import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

part 'session_database.g.dart';

// Table for cached AI insights
class AiInsights extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get recommendationsJson => text()();
  TextColumn get analysisDataJson => text()();
  DateTimeColumn get generatedAt => dateTime()();
}

// Table for quick tips cache
class QuickTips extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tipsJson => text()();
  DateTimeColumn get generatedAt => dateTime()();
}

// Define the table
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get email => text().withLength(min: 0, max: 100)();
  IntColumn get elapsedTimeMs => integer()();
  TextColumn get weightUnit => text()();
  DateTimeColumn get sessionTime => dateTime()();
  TextColumn get graphData => text()(); // Store JSON data as a string
  TextColumn get data => text()();
}

@DriftDatabase(tables: [Sessions, AiInsights, QuickTips])
class SessionDatabase extends _$SessionDatabase {
  // Private constructor for singleton pattern
  SessionDatabase._() : super(_openConnection());

  // Singleton instance
  static final SessionDatabase _instance = SessionDatabase._();

  // Factory constructor to return the singleton instance
  factory SessionDatabase() {
    return _instance;
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Create new tables added in version 2
            await m.createTable(aiInsights);
            await m.createTable(quickTips);
          }
        },
      );

  Future<int> insertSession(SessionsCompanion session) =>
      into(sessions).insert(session);

  Future<List<Session>> getAllSessions() => select(sessions).get();

  Future<int> deleteSession(int id) =>
      (delete(sessions)..where((tbl) => tbl.id.equals(id))).go();

  Future<void> updateSession(Session session) async {
    await into(sessions).insert(
      SessionsCompanion(
        id: Value(session.id),
        name: Value(session.name),
        email: Value(session.email),
        elapsedTimeMs: Value(session.elapsedTimeMs),
        weightUnit: Value(session.weightUnit),
        sessionTime: Value(session.sessionTime),
        graphData: Value(session.graphData),
        data: Value(session.data),
      ),
      mode: InsertMode.replace,
    );
  }

  // ----- AI Insights helpers -----

  Future<int> insertInsight(AiInsightsCompanion insight) =>
      into(aiInsights).insert(insight);

  Future<AiInsight?> getLatestInsight() async {
    return (select(aiInsights)
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.generatedAt, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> clearInsights() async {
    await delete(aiInsights).go();
  }

  // ----- Quick tips helpers -----

  Future<int> insertQuickTip(QuickTipsCompanion tip) =>
      into(quickTips).insert(tip);

  Future<QuickTip?> getLatestQuickTip() async {
    return (select(quickTips)
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.generatedAt, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> clearQuickTips() async {
    await delete(quickTips).go();
  }
}

// Use SqfliteQueryExecutor instead of NativeDatabase or FlutterQueryExecutor
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(join(dbFolder.path, 'sessions.sqlite'));
    return SqfliteQueryExecutor.inDatabaseFolder(path: file.path);
  });
}
