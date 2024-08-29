import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

part 'session_database.g.dart';

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

@DriftDatabase(tables: [Sessions])
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
  int get schemaVersion => 1;

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
}

// Use SqfliteQueryExecutor instead of NativeDatabase or FlutterQueryExecutor
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(join(dbFolder.path, 'sessions.sqlite'));
    return SqfliteQueryExecutor.inDatabaseFolder(path: file.path);
  });
}