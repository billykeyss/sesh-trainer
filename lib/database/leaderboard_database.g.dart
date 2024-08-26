// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_database.dart';

// ignore_for_file: type=lint
class $LeaderboardEntriesTable extends LeaderboardEntries
    with TableInfo<$LeaderboardEntriesTable, LeaderboardEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LeaderboardEntriesTable(this.attachedDatabase, [this._alias]);
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
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _maxWeightMeta =
      const VerificationMeta('maxWeight');
  @override
  late final GeneratedColumn<double> maxWeight = GeneratedColumn<double>(
      'max_weight', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, email, maxWeight, gender, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'leaderboard_entries';
  @override
  VerificationContext validateIntegrity(Insertable<LeaderboardEntry> instance,
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
    }
    if (data.containsKey('max_weight')) {
      context.handle(_maxWeightMeta,
          maxWeight.isAcceptableOrUnknown(data['max_weight']!, _maxWeightMeta));
    } else if (isInserting) {
      context.missing(_maxWeightMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LeaderboardEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LeaderboardEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      maxWeight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_weight'])!,
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
    );
  }

  @override
  $LeaderboardEntriesTable createAlias(String alias) {
    return $LeaderboardEntriesTable(attachedDatabase, alias);
  }
}

class LeaderboardEntry extends DataClass
    implements Insertable<LeaderboardEntry> {
  final int id;
  final String name;
  final String? email;
  final double maxWeight;
  final String gender;
  final DateTime date;
  const LeaderboardEntry(
      {required this.id,
      required this.name,
      this.email,
      required this.maxWeight,
      required this.gender,
      required this.date});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['max_weight'] = Variable<double>(maxWeight);
    map['gender'] = Variable<String>(gender);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  LeaderboardEntriesCompanion toCompanion(bool nullToAbsent) {
    return LeaderboardEntriesCompanion(
      id: Value(id),
      name: Value(name),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      maxWeight: Value(maxWeight),
      gender: Value(gender),
      date: Value(date),
    );
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LeaderboardEntry(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      maxWeight: serializer.fromJson<double>(json['maxWeight']),
      gender: serializer.fromJson<String>(json['gender']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String?>(email),
      'maxWeight': serializer.toJson<double>(maxWeight),
      'gender': serializer.toJson<String>(gender),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  LeaderboardEntry copyWith(
          {int? id,
          String? name,
          Value<String?> email = const Value.absent(),
          double? maxWeight,
          String? gender,
          DateTime? date}) =>
      LeaderboardEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email.present ? email.value : this.email,
        maxWeight: maxWeight ?? this.maxWeight,
        gender: gender ?? this.gender,
        date: date ?? this.date,
      );
  LeaderboardEntry copyWithCompanion(LeaderboardEntriesCompanion data) {
    return LeaderboardEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      maxWeight: data.maxWeight.present ? data.maxWeight.value : this.maxWeight,
      gender: data.gender.present ? data.gender.value : this.gender,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LeaderboardEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('maxWeight: $maxWeight, ')
          ..write('gender: $gender, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, email, maxWeight, gender, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LeaderboardEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.maxWeight == this.maxWeight &&
          other.gender == this.gender &&
          other.date == this.date);
}

class LeaderboardEntriesCompanion extends UpdateCompanion<LeaderboardEntry> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> email;
  final Value<double> maxWeight;
  final Value<String> gender;
  final Value<DateTime> date;
  const LeaderboardEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.maxWeight = const Value.absent(),
    this.gender = const Value.absent(),
    this.date = const Value.absent(),
  });
  LeaderboardEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.email = const Value.absent(),
    required double maxWeight,
    required String gender,
    required DateTime date,
  })  : name = Value(name),
        maxWeight = Value(maxWeight),
        gender = Value(gender),
        date = Value(date);
  static Insertable<LeaderboardEntry> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<double>? maxWeight,
    Expression<String>? gender,
    Expression<DateTime>? date,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (maxWeight != null) 'max_weight': maxWeight,
      if (gender != null) 'gender': gender,
      if (date != null) 'date': date,
    });
  }

  LeaderboardEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? email,
      Value<double>? maxWeight,
      Value<String>? gender,
      Value<DateTime>? date}) {
    return LeaderboardEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      maxWeight: maxWeight ?? this.maxWeight,
      gender: gender ?? this.gender,
      date: date ?? this.date,
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
    if (maxWeight.present) {
      map['max_weight'] = Variable<double>(maxWeight.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LeaderboardEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('maxWeight: $maxWeight, ')
          ..write('gender: $gender, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }
}

abstract class _$LeaderboardDatabase extends GeneratedDatabase {
  _$LeaderboardDatabase(QueryExecutor e) : super(e);
  $LeaderboardDatabaseManager get managers => $LeaderboardDatabaseManager(this);
  late final $LeaderboardEntriesTable leaderboardEntries =
      $LeaderboardEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [leaderboardEntries];
}

typedef $$LeaderboardEntriesTableCreateCompanionBuilder
    = LeaderboardEntriesCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> email,
  required double maxWeight,
  required String gender,
  required DateTime date,
});
typedef $$LeaderboardEntriesTableUpdateCompanionBuilder
    = LeaderboardEntriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> email,
  Value<double> maxWeight,
  Value<String> gender,
  Value<DateTime> date,
});

class $$LeaderboardEntriesTableFilterComposer
    extends FilterComposer<_$LeaderboardDatabase, $LeaderboardEntriesTable> {
  $$LeaderboardEntriesTableFilterComposer(super.$state);
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

  ColumnFilters<double> get maxWeight => $state.composableBuilder(
      column: $state.table.maxWeight,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get gender => $state.composableBuilder(
      column: $state.table.gender,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LeaderboardEntriesTableOrderingComposer
    extends OrderingComposer<_$LeaderboardDatabase, $LeaderboardEntriesTable> {
  $$LeaderboardEntriesTableOrderingComposer(super.$state);
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

  ColumnOrderings<double> get maxWeight => $state.composableBuilder(
      column: $state.table.maxWeight,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get gender => $state.composableBuilder(
      column: $state.table.gender,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$LeaderboardEntriesTableTableManager extends RootTableManager<
    _$LeaderboardDatabase,
    $LeaderboardEntriesTable,
    LeaderboardEntry,
    $$LeaderboardEntriesTableFilterComposer,
    $$LeaderboardEntriesTableOrderingComposer,
    $$LeaderboardEntriesTableCreateCompanionBuilder,
    $$LeaderboardEntriesTableUpdateCompanionBuilder,
    (
      LeaderboardEntry,
      BaseReferences<_$LeaderboardDatabase, $LeaderboardEntriesTable,
          LeaderboardEntry>
    ),
    LeaderboardEntry,
    PrefetchHooks Function()> {
  $$LeaderboardEntriesTableTableManager(
      _$LeaderboardDatabase db, $LeaderboardEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LeaderboardEntriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$LeaderboardEntriesTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<double> maxWeight = const Value.absent(),
            Value<String> gender = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
          }) =>
              LeaderboardEntriesCompanion(
            id: id,
            name: name,
            email: email,
            maxWeight: maxWeight,
            gender: gender,
            date: date,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> email = const Value.absent(),
            required double maxWeight,
            required String gender,
            required DateTime date,
          }) =>
              LeaderboardEntriesCompanion.insert(
            id: id,
            name: name,
            email: email,
            maxWeight: maxWeight,
            gender: gender,
            date: date,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LeaderboardEntriesTableProcessedTableManager = ProcessedTableManager<
    _$LeaderboardDatabase,
    $LeaderboardEntriesTable,
    LeaderboardEntry,
    $$LeaderboardEntriesTableFilterComposer,
    $$LeaderboardEntriesTableOrderingComposer,
    $$LeaderboardEntriesTableCreateCompanionBuilder,
    $$LeaderboardEntriesTableUpdateCompanionBuilder,
    (
      LeaderboardEntry,
      BaseReferences<_$LeaderboardDatabase, $LeaderboardEntriesTable,
          LeaderboardEntry>
    ),
    LeaderboardEntry,
    PrefetchHooks Function()>;

class $LeaderboardDatabaseManager {
  final _$LeaderboardDatabase _db;
  $LeaderboardDatabaseManager(this._db);
  $$LeaderboardEntriesTableTableManager get leaderboardEntries =>
      $$LeaderboardEntriesTableTableManager(_db, _db.leaderboardEntries);
}
