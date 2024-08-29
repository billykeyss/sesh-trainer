// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 0, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _elapsedTimeMsMeta =
      const VerificationMeta('elapsedTimeMs');
  @override
  late final GeneratedColumn<int> elapsedTimeMs = GeneratedColumn<int>(
      'elapsed_time_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weightUnitMeta =
      const VerificationMeta('weightUnit');
  @override
  late final GeneratedColumn<String> weightUnit = GeneratedColumn<String>(
      'weight_unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionTimeMeta =
      const VerificationMeta('sessionTime');
  @override
  late final GeneratedColumn<DateTime> sessionTime = GeneratedColumn<DateTime>(
      'session_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _graphDataMeta =
      const VerificationMeta('graphData');
  @override
  late final GeneratedColumn<String> graphData = GeneratedColumn<String>(
      'graph_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        email,
        elapsedTimeMs,
        weightUnit,
        sessionTime,
        graphData,
        data
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(Insertable<Session> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('elapsed_time_ms')) {
      context.handle(
          _elapsedTimeMsMeta,
          elapsedTimeMs.isAcceptableOrUnknown(
              data['elapsed_time_ms']!, _elapsedTimeMsMeta));
    } else if (isInserting) {
      context.missing(_elapsedTimeMsMeta);
    }
    if (data.containsKey('weight_unit')) {
      context.handle(
          _weightUnitMeta,
          weightUnit.isAcceptableOrUnknown(
              data['weight_unit']!, _weightUnitMeta));
    } else if (isInserting) {
      context.missing(_weightUnitMeta);
    }
    if (data.containsKey('session_time')) {
      context.handle(
          _sessionTimeMeta,
          sessionTime.isAcceptableOrUnknown(
              data['session_time']!, _sessionTimeMeta));
    } else if (isInserting) {
      context.missing(_sessionTimeMeta);
    }
    if (data.containsKey('graph_data')) {
      context.handle(_graphDataMeta,
          graphData.isAcceptableOrUnknown(data['graph_data']!, _graphDataMeta));
    } else if (isInserting) {
      context.missing(_graphDataMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      elapsedTimeMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}elapsed_time_ms'])!,
      weightUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}weight_unit'])!,
      sessionTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}session_time'])!,
      graphData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}graph_data'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final String name;
  final String email;
  final int elapsedTimeMs;
  final String weightUnit;
  final DateTime sessionTime;
  final String graphData;
  final String data;
  const Session(
      {required this.id,
      required this.name,
      required this.email,
      required this.elapsedTimeMs,
      required this.weightUnit,
      required this.sessionTime,
      required this.graphData,
      required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    map['elapsed_time_ms'] = Variable<int>(elapsedTimeMs);
    map['weight_unit'] = Variable<String>(weightUnit);
    map['session_time'] = Variable<DateTime>(sessionTime);
    map['graph_data'] = Variable<String>(graphData);
    map['data'] = Variable<String>(data);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      elapsedTimeMs: Value(elapsedTimeMs),
      weightUnit: Value(weightUnit),
      sessionTime: Value(sessionTime),
      graphData: Value(graphData),
      data: Value(data),
    );
  }

  factory Session.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      elapsedTimeMs: serializer.fromJson<int>(json['elapsedTimeMs']),
      weightUnit: serializer.fromJson<String>(json['weightUnit']),
      sessionTime: serializer.fromJson<DateTime>(json['sessionTime']),
      graphData: serializer.fromJson<String>(json['graphData']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'elapsedTimeMs': serializer.toJson<int>(elapsedTimeMs),
      'weightUnit': serializer.toJson<String>(weightUnit),
      'sessionTime': serializer.toJson<DateTime>(sessionTime),
      'graphData': serializer.toJson<String>(graphData),
      'data': serializer.toJson<String>(data),
    };
  }

  Session copyWith(
          {int? id,
          String? name,
          String? email,
          int? elapsedTimeMs,
          String? weightUnit,
          DateTime? sessionTime,
          String? graphData,
          String? data}) =>
      Session(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        elapsedTimeMs: elapsedTimeMs ?? this.elapsedTimeMs,
        weightUnit: weightUnit ?? this.weightUnit,
        sessionTime: sessionTime ?? this.sessionTime,
        graphData: graphData ?? this.graphData,
        data: data ?? this.data,
      );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      elapsedTimeMs: data.elapsedTimeMs.present
          ? data.elapsedTimeMs.value
          : this.elapsedTimeMs,
      weightUnit:
          data.weightUnit.present ? data.weightUnit.value : this.weightUnit,
      sessionTime:
          data.sessionTime.present ? data.sessionTime.value : this.sessionTime,
      graphData: data.graphData.present ? data.graphData.value : this.graphData,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('elapsedTimeMs: $elapsedTimeMs, ')
          ..write('weightUnit: $weightUnit, ')
          ..write('sessionTime: $sessionTime, ')
          ..write('graphData: $graphData, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, email, elapsedTimeMs, weightUnit, sessionTime, graphData, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.elapsedTimeMs == this.elapsedTimeMs &&
          other.weightUnit == this.weightUnit &&
          other.sessionTime == this.sessionTime &&
          other.graphData == this.graphData &&
          other.data == this.data);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> email;
  final Value<int> elapsedTimeMs;
  final Value<String> weightUnit;
  final Value<DateTime> sessionTime;
  final Value<String> graphData;
  final Value<String> data;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.elapsedTimeMs = const Value.absent(),
    this.weightUnit = const Value.absent(),
    this.sessionTime = const Value.absent(),
    this.graphData = const Value.absent(),
    this.data = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String email,
    required int elapsedTimeMs,
    required String weightUnit,
    required DateTime sessionTime,
    required String graphData,
    required String data,
  })  : name = Value(name),
        email = Value(email),
        elapsedTimeMs = Value(elapsedTimeMs),
        weightUnit = Value(weightUnit),
        sessionTime = Value(sessionTime),
        graphData = Value(graphData),
        data = Value(data);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<int>? elapsedTimeMs,
    Expression<String>? weightUnit,
    Expression<DateTime>? sessionTime,
    Expression<String>? graphData,
    Expression<String>? data,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (elapsedTimeMs != null) 'elapsed_time_ms': elapsedTimeMs,
      if (weightUnit != null) 'weight_unit': weightUnit,
      if (sessionTime != null) 'session_time': sessionTime,
      if (graphData != null) 'graph_data': graphData,
      if (data != null) 'data': data,
    });
  }

  SessionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? email,
      Value<int>? elapsedTimeMs,
      Value<String>? weightUnit,
      Value<DateTime>? sessionTime,
      Value<String>? graphData,
      Value<String>? data}) {
    return SessionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      elapsedTimeMs: elapsedTimeMs ?? this.elapsedTimeMs,
      weightUnit: weightUnit ?? this.weightUnit,
      sessionTime: sessionTime ?? this.sessionTime,
      graphData: graphData ?? this.graphData,
      data: data ?? this.data,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (elapsedTimeMs.present) {
      map['elapsed_time_ms'] = Variable<int>(elapsedTimeMs.value);
    }
    if (weightUnit.present) {
      map['weight_unit'] = Variable<String>(weightUnit.value);
    }
    if (sessionTime.present) {
      map['session_time'] = Variable<DateTime>(sessionTime.value);
    }
    if (graphData.present) {
      map['graph_data'] = Variable<String>(graphData.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('elapsedTimeMs: $elapsedTimeMs, ')
          ..write('weightUnit: $weightUnit, ')
          ..write('sessionTime: $sessionTime, ')
          ..write('graphData: $graphData, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }
}

abstract class _$SessionDatabase extends GeneratedDatabase {
  _$SessionDatabase(QueryExecutor e) : super(e);
  $SessionDatabaseManager get managers => $SessionDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sessions];
}

typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required String name,
  required String email,
  required int elapsedTimeMs,
  required String weightUnit,
  required DateTime sessionTime,
  required String graphData,
  required String data,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> email,
  Value<int> elapsedTimeMs,
  Value<String> weightUnit,
  Value<DateTime> sessionTime,
  Value<String> graphData,
  Value<String> data,
});

class $$SessionsTableFilterComposer
    extends FilterComposer<_$SessionDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get elapsedTimeMs => $state.composableBuilder(
      column: $state.table.elapsedTimeMs,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get weightUnit => $state.composableBuilder(
      column: $state.table.weightUnit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get sessionTime => $state.composableBuilder(
      column: $state.table.sessionTime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get graphData => $state.composableBuilder(
      column: $state.table.graphData,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get data => $state.composableBuilder(
      column: $state.table.data,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SessionsTableOrderingComposer
    extends OrderingComposer<_$SessionDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get elapsedTimeMs => $state.composableBuilder(
      column: $state.table.elapsedTimeMs,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get weightUnit => $state.composableBuilder(
      column: $state.table.weightUnit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get sessionTime => $state.composableBuilder(
      column: $state.table.sessionTime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get graphData => $state.composableBuilder(
      column: $state.table.graphData,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get data => $state.composableBuilder(
      column: $state.table.data,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$SessionsTableTableManager extends RootTableManager<
    _$SessionDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (Session, BaseReferences<_$SessionDatabase, $SessionsTable, Session>),
    Session,
    PrefetchHooks Function()> {
  $$SessionsTableTableManager(_$SessionDatabase db, $SessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SessionsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SessionsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<int> elapsedTimeMs = const Value.absent(),
            Value<String> weightUnit = const Value.absent(),
            Value<DateTime> sessionTime = const Value.absent(),
            Value<String> graphData = const Value.absent(),
            Value<String> data = const Value.absent(),
          }) =>
              SessionsCompanion(
            id: id,
            name: name,
            email: email,
            elapsedTimeMs: elapsedTimeMs,
            weightUnit: weightUnit,
            sessionTime: sessionTime,
            graphData: graphData,
            data: data,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String email,
            required int elapsedTimeMs,
            required String weightUnit,
            required DateTime sessionTime,
            required String graphData,
            required String data,
          }) =>
              SessionsCompanion.insert(
            id: id,
            name: name,
            email: email,
            elapsedTimeMs: elapsedTimeMs,
            weightUnit: weightUnit,
            sessionTime: sessionTime,
            graphData: graphData,
            data: data,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SessionsTableProcessedTableManager = ProcessedTableManager<
    _$SessionDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (Session, BaseReferences<_$SessionDatabase, $SessionsTable, Session>),
    Session,
    PrefetchHooks Function()>;

class $SessionDatabaseManager {
  final _$SessionDatabase _db;
  $SessionDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
}
