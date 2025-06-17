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

class $AiInsightsTable extends AiInsights
    with TableInfo<$AiInsightsTable, AiInsight> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiInsightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _recommendationsJsonMeta =
      const VerificationMeta('recommendationsJson');
  @override
  late final GeneratedColumn<String> recommendationsJson =
      GeneratedColumn<String>('recommendations_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _analysisDataJsonMeta =
      const VerificationMeta('analysisDataJson');
  @override
  late final GeneratedColumn<String> analysisDataJson = GeneratedColumn<String>(
      'analysis_data_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, recommendationsJson, analysisDataJson, generatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_insights';
  @override
  VerificationContext validateIntegrity(Insertable<AiInsight> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recommendations_json')) {
      context.handle(
          _recommendationsJsonMeta,
          recommendationsJson.isAcceptableOrUnknown(
              data['recommendations_json']!, _recommendationsJsonMeta));
    } else if (isInserting) {
      context.missing(_recommendationsJsonMeta);
    }
    if (data.containsKey('analysis_data_json')) {
      context.handle(
          _analysisDataJsonMeta,
          analysisDataJson.isAcceptableOrUnknown(
              data['analysis_data_json']!, _analysisDataJsonMeta));
    } else if (isInserting) {
      context.missing(_analysisDataJsonMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiInsight map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiInsight(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      recommendationsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}recommendations_json'])!,
      analysisDataJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}analysis_data_json'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}generated_at'])!,
    );
  }

  @override
  $AiInsightsTable createAlias(String alias) {
    return $AiInsightsTable(attachedDatabase, alias);
  }
}

class AiInsight extends DataClass implements Insertable<AiInsight> {
  final int id;
  final String recommendationsJson;
  final String analysisDataJson;
  final DateTime generatedAt;
  const AiInsight(
      {required this.id,
      required this.recommendationsJson,
      required this.analysisDataJson,
      required this.generatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recommendations_json'] = Variable<String>(recommendationsJson);
    map['analysis_data_json'] = Variable<String>(analysisDataJson);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    return map;
  }

  AiInsightsCompanion toCompanion(bool nullToAbsent) {
    return AiInsightsCompanion(
      id: Value(id),
      recommendationsJson: Value(recommendationsJson),
      analysisDataJson: Value(analysisDataJson),
      generatedAt: Value(generatedAt),
    );
  }

  factory AiInsight.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiInsight(
      id: serializer.fromJson<int>(json['id']),
      recommendationsJson:
          serializer.fromJson<String>(json['recommendationsJson']),
      analysisDataJson: serializer.fromJson<String>(json['analysisDataJson']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recommendationsJson': serializer.toJson<String>(recommendationsJson),
      'analysisDataJson': serializer.toJson<String>(analysisDataJson),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
    };
  }

  AiInsight copyWith(
          {int? id,
          String? recommendationsJson,
          String? analysisDataJson,
          DateTime? generatedAt}) =>
      AiInsight(
        id: id ?? this.id,
        recommendationsJson: recommendationsJson ?? this.recommendationsJson,
        analysisDataJson: analysisDataJson ?? this.analysisDataJson,
        generatedAt: generatedAt ?? this.generatedAt,
      );
  AiInsight copyWithCompanion(AiInsightsCompanion data) {
    return AiInsight(
      id: data.id.present ? data.id.value : this.id,
      recommendationsJson: data.recommendationsJson.present
          ? data.recommendationsJson.value
          : this.recommendationsJson,
      analysisDataJson: data.analysisDataJson.present
          ? data.analysisDataJson.value
          : this.analysisDataJson,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiInsight(')
          ..write('id: $id, ')
          ..write('recommendationsJson: $recommendationsJson, ')
          ..write('analysisDataJson: $analysisDataJson, ')
          ..write('generatedAt: $generatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, recommendationsJson, analysisDataJson, generatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiInsight &&
          other.id == this.id &&
          other.recommendationsJson == this.recommendationsJson &&
          other.analysisDataJson == this.analysisDataJson &&
          other.generatedAt == this.generatedAt);
}

class AiInsightsCompanion extends UpdateCompanion<AiInsight> {
  final Value<int> id;
  final Value<String> recommendationsJson;
  final Value<String> analysisDataJson;
  final Value<DateTime> generatedAt;
  const AiInsightsCompanion({
    this.id = const Value.absent(),
    this.recommendationsJson = const Value.absent(),
    this.analysisDataJson = const Value.absent(),
    this.generatedAt = const Value.absent(),
  });
  AiInsightsCompanion.insert({
    this.id = const Value.absent(),
    required String recommendationsJson,
    required String analysisDataJson,
    required DateTime generatedAt,
  })  : recommendationsJson = Value(recommendationsJson),
        analysisDataJson = Value(analysisDataJson),
        generatedAt = Value(generatedAt);
  static Insertable<AiInsight> custom({
    Expression<int>? id,
    Expression<String>? recommendationsJson,
    Expression<String>? analysisDataJson,
    Expression<DateTime>? generatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recommendationsJson != null)
        'recommendations_json': recommendationsJson,
      if (analysisDataJson != null) 'analysis_data_json': analysisDataJson,
      if (generatedAt != null) 'generated_at': generatedAt,
    });
  }

  AiInsightsCompanion copyWith(
      {Value<int>? id,
      Value<String>? recommendationsJson,
      Value<String>? analysisDataJson,
      Value<DateTime>? generatedAt}) {
    return AiInsightsCompanion(
      id: id ?? this.id,
      recommendationsJson: recommendationsJson ?? this.recommendationsJson,
      analysisDataJson: analysisDataJson ?? this.analysisDataJson,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recommendationsJson.present) {
      map['recommendations_json'] = Variable<String>(recommendationsJson.value);
    }
    if (analysisDataJson.present) {
      map['analysis_data_json'] = Variable<String>(analysisDataJson.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiInsightsCompanion(')
          ..write('id: $id, ')
          ..write('recommendationsJson: $recommendationsJson, ')
          ..write('analysisDataJson: $analysisDataJson, ')
          ..write('generatedAt: $generatedAt')
          ..write(')'))
        .toString();
  }
}

class $QuickTipsTable extends QuickTips
    with TableInfo<$QuickTipsTable, QuickTip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuickTipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tipsJsonMeta =
      const VerificationMeta('tipsJson');
  @override
  late final GeneratedColumn<String> tipsJson = GeneratedColumn<String>(
      'tips_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, tipsJson, generatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quick_tips';
  @override
  VerificationContext validateIntegrity(Insertable<QuickTip> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tips_json')) {
      context.handle(_tipsJsonMeta,
          tipsJson.isAcceptableOrUnknown(data['tips_json']!, _tipsJsonMeta));
    } else if (isInserting) {
      context.missing(_tipsJsonMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuickTip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuickTip(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tipsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tips_json'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}generated_at'])!,
    );
  }

  @override
  $QuickTipsTable createAlias(String alias) {
    return $QuickTipsTable(attachedDatabase, alias);
  }
}

class QuickTip extends DataClass implements Insertable<QuickTip> {
  final int id;
  final String tipsJson;
  final DateTime generatedAt;
  const QuickTip(
      {required this.id, required this.tipsJson, required this.generatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tips_json'] = Variable<String>(tipsJson);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    return map;
  }

  QuickTipsCompanion toCompanion(bool nullToAbsent) {
    return QuickTipsCompanion(
      id: Value(id),
      tipsJson: Value(tipsJson),
      generatedAt: Value(generatedAt),
    );
  }

  factory QuickTip.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuickTip(
      id: serializer.fromJson<int>(json['id']),
      tipsJson: serializer.fromJson<String>(json['tipsJson']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tipsJson': serializer.toJson<String>(tipsJson),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
    };
  }

  QuickTip copyWith({int? id, String? tipsJson, DateTime? generatedAt}) =>
      QuickTip(
        id: id ?? this.id,
        tipsJson: tipsJson ?? this.tipsJson,
        generatedAt: generatedAt ?? this.generatedAt,
      );
  QuickTip copyWithCompanion(QuickTipsCompanion data) {
    return QuickTip(
      id: data.id.present ? data.id.value : this.id,
      tipsJson: data.tipsJson.present ? data.tipsJson.value : this.tipsJson,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuickTip(')
          ..write('id: $id, ')
          ..write('tipsJson: $tipsJson, ')
          ..write('generatedAt: $generatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tipsJson, generatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuickTip &&
          other.id == this.id &&
          other.tipsJson == this.tipsJson &&
          other.generatedAt == this.generatedAt);
}

class QuickTipsCompanion extends UpdateCompanion<QuickTip> {
  final Value<int> id;
  final Value<String> tipsJson;
  final Value<DateTime> generatedAt;
  const QuickTipsCompanion({
    this.id = const Value.absent(),
    this.tipsJson = const Value.absent(),
    this.generatedAt = const Value.absent(),
  });
  QuickTipsCompanion.insert({
    this.id = const Value.absent(),
    required String tipsJson,
    required DateTime generatedAt,
  })  : tipsJson = Value(tipsJson),
        generatedAt = Value(generatedAt);
  static Insertable<QuickTip> custom({
    Expression<int>? id,
    Expression<String>? tipsJson,
    Expression<DateTime>? generatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tipsJson != null) 'tips_json': tipsJson,
      if (generatedAt != null) 'generated_at': generatedAt,
    });
  }

  QuickTipsCompanion copyWith(
      {Value<int>? id, Value<String>? tipsJson, Value<DateTime>? generatedAt}) {
    return QuickTipsCompanion(
      id: id ?? this.id,
      tipsJson: tipsJson ?? this.tipsJson,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tipsJson.present) {
      map['tips_json'] = Variable<String>(tipsJson.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuickTipsCompanion(')
          ..write('id: $id, ')
          ..write('tipsJson: $tipsJson, ')
          ..write('generatedAt: $generatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$SessionDatabase extends GeneratedDatabase {
  _$SessionDatabase(QueryExecutor e) : super(e);
  $SessionDatabaseManager get managers => $SessionDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $AiInsightsTable aiInsights = $AiInsightsTable(this);
  late final $QuickTipsTable quickTips = $QuickTipsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [sessions, aiInsights, quickTips];
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
typedef $$AiInsightsTableCreateCompanionBuilder = AiInsightsCompanion Function({
  Value<int> id,
  required String recommendationsJson,
  required String analysisDataJson,
  required DateTime generatedAt,
});
typedef $$AiInsightsTableUpdateCompanionBuilder = AiInsightsCompanion Function({
  Value<int> id,
  Value<String> recommendationsJson,
  Value<String> analysisDataJson,
  Value<DateTime> generatedAt,
});

class $$AiInsightsTableFilterComposer
    extends FilterComposer<_$SessionDatabase, $AiInsightsTable> {
  $$AiInsightsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get recommendationsJson => $state.composableBuilder(
      column: $state.table.recommendationsJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get analysisDataJson => $state.composableBuilder(
      column: $state.table.analysisDataJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get generatedAt => $state.composableBuilder(
      column: $state.table.generatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$AiInsightsTableOrderingComposer
    extends OrderingComposer<_$SessionDatabase, $AiInsightsTable> {
  $$AiInsightsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get recommendationsJson => $state.composableBuilder(
      column: $state.table.recommendationsJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get analysisDataJson => $state.composableBuilder(
      column: $state.table.analysisDataJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get generatedAt => $state.composableBuilder(
      column: $state.table.generatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$AiInsightsTableTableManager extends RootTableManager<
    _$SessionDatabase,
    $AiInsightsTable,
    AiInsight,
    $$AiInsightsTableFilterComposer,
    $$AiInsightsTableOrderingComposer,
    $$AiInsightsTableCreateCompanionBuilder,
    $$AiInsightsTableUpdateCompanionBuilder,
    (AiInsight, BaseReferences<_$SessionDatabase, $AiInsightsTable, AiInsight>),
    AiInsight,
    PrefetchHooks Function()> {
  $$AiInsightsTableTableManager(_$SessionDatabase db, $AiInsightsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AiInsightsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AiInsightsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> recommendationsJson = const Value.absent(),
            Value<String> analysisDataJson = const Value.absent(),
            Value<DateTime> generatedAt = const Value.absent(),
          }) =>
              AiInsightsCompanion(
            id: id,
            recommendationsJson: recommendationsJson,
            analysisDataJson: analysisDataJson,
            generatedAt: generatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String recommendationsJson,
            required String analysisDataJson,
            required DateTime generatedAt,
          }) =>
              AiInsightsCompanion.insert(
            id: id,
            recommendationsJson: recommendationsJson,
            analysisDataJson: analysisDataJson,
            generatedAt: generatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AiInsightsTableProcessedTableManager = ProcessedTableManager<
    _$SessionDatabase,
    $AiInsightsTable,
    AiInsight,
    $$AiInsightsTableFilterComposer,
    $$AiInsightsTableOrderingComposer,
    $$AiInsightsTableCreateCompanionBuilder,
    $$AiInsightsTableUpdateCompanionBuilder,
    (AiInsight, BaseReferences<_$SessionDatabase, $AiInsightsTable, AiInsight>),
    AiInsight,
    PrefetchHooks Function()>;
typedef $$QuickTipsTableCreateCompanionBuilder = QuickTipsCompanion Function({
  Value<int> id,
  required String tipsJson,
  required DateTime generatedAt,
});
typedef $$QuickTipsTableUpdateCompanionBuilder = QuickTipsCompanion Function({
  Value<int> id,
  Value<String> tipsJson,
  Value<DateTime> generatedAt,
});

class $$QuickTipsTableFilterComposer
    extends FilterComposer<_$SessionDatabase, $QuickTipsTable> {
  $$QuickTipsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tipsJson => $state.composableBuilder(
      column: $state.table.tipsJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get generatedAt => $state.composableBuilder(
      column: $state.table.generatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$QuickTipsTableOrderingComposer
    extends OrderingComposer<_$SessionDatabase, $QuickTipsTable> {
  $$QuickTipsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tipsJson => $state.composableBuilder(
      column: $state.table.tipsJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get generatedAt => $state.composableBuilder(
      column: $state.table.generatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$QuickTipsTableTableManager extends RootTableManager<
    _$SessionDatabase,
    $QuickTipsTable,
    QuickTip,
    $$QuickTipsTableFilterComposer,
    $$QuickTipsTableOrderingComposer,
    $$QuickTipsTableCreateCompanionBuilder,
    $$QuickTipsTableUpdateCompanionBuilder,
    (QuickTip, BaseReferences<_$SessionDatabase, $QuickTipsTable, QuickTip>),
    QuickTip,
    PrefetchHooks Function()> {
  $$QuickTipsTableTableManager(_$SessionDatabase db, $QuickTipsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$QuickTipsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$QuickTipsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> tipsJson = const Value.absent(),
            Value<DateTime> generatedAt = const Value.absent(),
          }) =>
              QuickTipsCompanion(
            id: id,
            tipsJson: tipsJson,
            generatedAt: generatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String tipsJson,
            required DateTime generatedAt,
          }) =>
              QuickTipsCompanion.insert(
            id: id,
            tipsJson: tipsJson,
            generatedAt: generatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuickTipsTableProcessedTableManager = ProcessedTableManager<
    _$SessionDatabase,
    $QuickTipsTable,
    QuickTip,
    $$QuickTipsTableFilterComposer,
    $$QuickTipsTableOrderingComposer,
    $$QuickTipsTableCreateCompanionBuilder,
    $$QuickTipsTableUpdateCompanionBuilder,
    (QuickTip, BaseReferences<_$SessionDatabase, $QuickTipsTable, QuickTip>),
    QuickTip,
    PrefetchHooks Function()>;

class $SessionDatabaseManager {
  final _$SessionDatabase _db;
  $SessionDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$AiInsightsTableTableManager get aiInsights =>
      $$AiInsightsTableTableManager(_db, _db.aiInsights);
  $$QuickTipsTableTableManager get quickTips =>
      $$QuickTipsTableTableManager(_db, _db.quickTips);
}
