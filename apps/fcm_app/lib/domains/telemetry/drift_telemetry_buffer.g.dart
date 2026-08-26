// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_telemetry_buffer.dart';

// ignore_for_file: type=lint
class $BufferedEventsTable extends BufferedEvents
    with TableInfo<$BufferedEventsTable, BufferedEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BufferedEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _traceIdMeta = const VerificationMeta(
    'traceId',
  );
  @override
  late final GeneratedColumn<String> traceId = GeneratedColumn<String>(
    'trace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMicrosMeta = const VerificationMeta(
    'atMicros',
  );
  @override
  late final GeneratedColumn<int> atMicros = GeneratedColumn<int>(
    'at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scenarioIdMeta = const VerificationMeta(
    'scenarioId',
  );
  @override
  late final GeneratedColumn<String> scenarioId = GeneratedColumn<String>(
    'scenario_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    traceId,
    type,
    atMicros,
    deviceId,
    scenarioId,
    detail,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'buffered_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<BufferedEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trace_id')) {
      context.handle(
        _traceIdMeta,
        traceId.isAcceptableOrUnknown(data['trace_id']!, _traceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_traceIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('at_micros')) {
      context.handle(
        _atMicrosMeta,
        atMicros.isAcceptableOrUnknown(data['at_micros']!, _atMicrosMeta),
      );
    } else if (isInserting) {
      context.missing(_atMicrosMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('scenario_id')) {
      context.handle(
        _scenarioIdMeta,
        scenarioId.isAcceptableOrUnknown(data['scenario_id']!, _scenarioIdMeta),
      );
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BufferedEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BufferedEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      traceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trace_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      atMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at_micros'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      scenarioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scenario_id'],
      ),
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
    );
  }

  @override
  $BufferedEventsTable createAlias(String alias) {
    return $BufferedEventsTable(attachedDatabase, alias);
  }
}

class BufferedEvent extends DataClass implements Insertable<BufferedEvent> {
  /// Surfaced as `PendingEvent.id`. Load-bearing: this buffer keeps duplicates on
  /// purpose, so this is the only thing that distinguishes two identical events.
  final int id;
  final String traceId;

  /// The event type's wire name, not its `Enum.index` — an index means a position
  /// in a Dart declaration, so inserting a value into `TelemetryEventType` would
  /// silently retype every buffered row.
  final String type;

  /// Microseconds since the Unix epoch in UTC.
  ///
  /// Not Drift's `dateTime()`, which stores whole seconds and would make a 300 ms
  /// delivery read as zero. Not ISO-8601 text either: `pending` sorts on this
  /// column, and `toIso8601String` emits three or six fractional digits, so a
  /// lexicographic sort puts `…02.000Z` *after* `…02.000001Z`.
  final int atMicros;
  final String deviceId;

  /// Nullable rather than defaulted to `''`: "no scenario" and "a scenario named
  /// nothing" are different answers when reading the matrix.
  final String? scenarioId;
  final String? detail;
  const BufferedEvent({
    required this.id,
    required this.traceId,
    required this.type,
    required this.atMicros,
    required this.deviceId,
    this.scenarioId,
    this.detail,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trace_id'] = Variable<String>(traceId);
    map['type'] = Variable<String>(type);
    map['at_micros'] = Variable<int>(atMicros);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || scenarioId != null) {
      map['scenario_id'] = Variable<String>(scenarioId);
    }
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    return map;
  }

  BufferedEventsCompanion toCompanion(bool nullToAbsent) {
    return BufferedEventsCompanion(
      id: Value(id),
      traceId: Value(traceId),
      type: Value(type),
      atMicros: Value(atMicros),
      deviceId: Value(deviceId),
      scenarioId: scenarioId == null && nullToAbsent
          ? const Value.absent()
          : Value(scenarioId),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
    );
  }

  factory BufferedEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BufferedEvent(
      id: serializer.fromJson<int>(json['id']),
      traceId: serializer.fromJson<String>(json['traceId']),
      type: serializer.fromJson<String>(json['type']),
      atMicros: serializer.fromJson<int>(json['atMicros']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      scenarioId: serializer.fromJson<String?>(json['scenarioId']),
      detail: serializer.fromJson<String?>(json['detail']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'traceId': serializer.toJson<String>(traceId),
      'type': serializer.toJson<String>(type),
      'atMicros': serializer.toJson<int>(atMicros),
      'deviceId': serializer.toJson<String>(deviceId),
      'scenarioId': serializer.toJson<String?>(scenarioId),
      'detail': serializer.toJson<String?>(detail),
    };
  }

  BufferedEvent copyWith({
    int? id,
    String? traceId,
    String? type,
    int? atMicros,
    String? deviceId,
    Value<String?> scenarioId = const Value.absent(),
    Value<String?> detail = const Value.absent(),
  }) => BufferedEvent(
    id: id ?? this.id,
    traceId: traceId ?? this.traceId,
    type: type ?? this.type,
    atMicros: atMicros ?? this.atMicros,
    deviceId: deviceId ?? this.deviceId,
    scenarioId: scenarioId.present ? scenarioId.value : this.scenarioId,
    detail: detail.present ? detail.value : this.detail,
  );
  BufferedEvent copyWithCompanion(BufferedEventsCompanion data) {
    return BufferedEvent(
      id: data.id.present ? data.id.value : this.id,
      traceId: data.traceId.present ? data.traceId.value : this.traceId,
      type: data.type.present ? data.type.value : this.type,
      atMicros: data.atMicros.present ? data.atMicros.value : this.atMicros,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      scenarioId: data.scenarioId.present
          ? data.scenarioId.value
          : this.scenarioId,
      detail: data.detail.present ? data.detail.value : this.detail,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BufferedEvent(')
          ..write('id: $id, ')
          ..write('traceId: $traceId, ')
          ..write('type: $type, ')
          ..write('atMicros: $atMicros, ')
          ..write('deviceId: $deviceId, ')
          ..write('scenarioId: $scenarioId, ')
          ..write('detail: $detail')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, traceId, type, atMicros, deviceId, scenarioId, detail);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BufferedEvent &&
          other.id == this.id &&
          other.traceId == this.traceId &&
          other.type == this.type &&
          other.atMicros == this.atMicros &&
          other.deviceId == this.deviceId &&
          other.scenarioId == this.scenarioId &&
          other.detail == this.detail);
}

class BufferedEventsCompanion extends UpdateCompanion<BufferedEvent> {
  final Value<int> id;
  final Value<String> traceId;
  final Value<String> type;
  final Value<int> atMicros;
  final Value<String> deviceId;
  final Value<String?> scenarioId;
  final Value<String?> detail;
  const BufferedEventsCompanion({
    this.id = const Value.absent(),
    this.traceId = const Value.absent(),
    this.type = const Value.absent(),
    this.atMicros = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.scenarioId = const Value.absent(),
    this.detail = const Value.absent(),
  });
  BufferedEventsCompanion.insert({
    this.id = const Value.absent(),
    required String traceId,
    required String type,
    required int atMicros,
    required String deviceId,
    this.scenarioId = const Value.absent(),
    this.detail = const Value.absent(),
  }) : traceId = Value(traceId),
       type = Value(type),
       atMicros = Value(atMicros),
       deviceId = Value(deviceId);
  static Insertable<BufferedEvent> custom({
    Expression<int>? id,
    Expression<String>? traceId,
    Expression<String>? type,
    Expression<int>? atMicros,
    Expression<String>? deviceId,
    Expression<String>? scenarioId,
    Expression<String>? detail,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (traceId != null) 'trace_id': traceId,
      if (type != null) 'type': type,
      if (atMicros != null) 'at_micros': atMicros,
      if (deviceId != null) 'device_id': deviceId,
      if (scenarioId != null) 'scenario_id': scenarioId,
      if (detail != null) 'detail': detail,
    });
  }

  BufferedEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? traceId,
    Value<String>? type,
    Value<int>? atMicros,
    Value<String>? deviceId,
    Value<String?>? scenarioId,
    Value<String?>? detail,
  }) {
    return BufferedEventsCompanion(
      id: id ?? this.id,
      traceId: traceId ?? this.traceId,
      type: type ?? this.type,
      atMicros: atMicros ?? this.atMicros,
      deviceId: deviceId ?? this.deviceId,
      scenarioId: scenarioId ?? this.scenarioId,
      detail: detail ?? this.detail,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (traceId.present) {
      map['trace_id'] = Variable<String>(traceId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (atMicros.present) {
      map['at_micros'] = Variable<int>(atMicros.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (scenarioId.present) {
      map['scenario_id'] = Variable<String>(scenarioId.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BufferedEventsCompanion(')
          ..write('id: $id, ')
          ..write('traceId: $traceId, ')
          ..write('type: $type, ')
          ..write('atMicros: $atMicros, ')
          ..write('deviceId: $deviceId, ')
          ..write('scenarioId: $scenarioId, ')
          ..write('detail: $detail')
          ..write(')'))
        .toString();
  }
}

abstract class _$DriftTelemetryBuffer extends GeneratedDatabase {
  _$DriftTelemetryBuffer(QueryExecutor e) : super(e);
  $DriftTelemetryBufferManager get managers =>
      $DriftTelemetryBufferManager(this);
  late final $BufferedEventsTable bufferedEvents = $BufferedEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [bufferedEvents];
}

typedef $$BufferedEventsTableCreateCompanionBuilder =
    BufferedEventsCompanion Function({
      Value<int> id,
      required String traceId,
      required String type,
      required int atMicros,
      required String deviceId,
      Value<String?> scenarioId,
      Value<String?> detail,
    });
typedef $$BufferedEventsTableUpdateCompanionBuilder =
    BufferedEventsCompanion Function({
      Value<int> id,
      Value<String> traceId,
      Value<String> type,
      Value<int> atMicros,
      Value<String> deviceId,
      Value<String?> scenarioId,
      Value<String?> detail,
    });

class $$BufferedEventsTableFilterComposer
    extends Composer<_$DriftTelemetryBuffer, $BufferedEventsTable> {
  $$BufferedEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get traceId => $composableBuilder(
    column: $table.traceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get atMicros => $composableBuilder(
    column: $table.atMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scenarioId => $composableBuilder(
    column: $table.scenarioId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BufferedEventsTableOrderingComposer
    extends Composer<_$DriftTelemetryBuffer, $BufferedEventsTable> {
  $$BufferedEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get traceId => $composableBuilder(
    column: $table.traceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get atMicros => $composableBuilder(
    column: $table.atMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scenarioId => $composableBuilder(
    column: $table.scenarioId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BufferedEventsTableAnnotationComposer
    extends Composer<_$DriftTelemetryBuffer, $BufferedEventsTable> {
  $$BufferedEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get traceId =>
      $composableBuilder(column: $table.traceId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get atMicros =>
      $composableBuilder(column: $table.atMicros, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get scenarioId => $composableBuilder(
    column: $table.scenarioId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);
}

class $$BufferedEventsTableTableManager
    extends
        RootTableManager<
          _$DriftTelemetryBuffer,
          $BufferedEventsTable,
          BufferedEvent,
          $$BufferedEventsTableFilterComposer,
          $$BufferedEventsTableOrderingComposer,
          $$BufferedEventsTableAnnotationComposer,
          $$BufferedEventsTableCreateCompanionBuilder,
          $$BufferedEventsTableUpdateCompanionBuilder,
          (
            BufferedEvent,
            BaseReferences<
              _$DriftTelemetryBuffer,
              $BufferedEventsTable,
              BufferedEvent
            >,
          ),
          BufferedEvent,
          PrefetchHooks Function()
        > {
  $$BufferedEventsTableTableManager(
    _$DriftTelemetryBuffer db,
    $BufferedEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BufferedEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BufferedEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BufferedEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> traceId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> atMicros = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String?> scenarioId = const Value.absent(),
                Value<String?> detail = const Value.absent(),
              }) => BufferedEventsCompanion(
                id: id,
                traceId: traceId,
                type: type,
                atMicros: atMicros,
                deviceId: deviceId,
                scenarioId: scenarioId,
                detail: detail,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String traceId,
                required String type,
                required int atMicros,
                required String deviceId,
                Value<String?> scenarioId = const Value.absent(),
                Value<String?> detail = const Value.absent(),
              }) => BufferedEventsCompanion.insert(
                id: id,
                traceId: traceId,
                type: type,
                atMicros: atMicros,
                deviceId: deviceId,
                scenarioId: scenarioId,
                detail: detail,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BufferedEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$DriftTelemetryBuffer,
      $BufferedEventsTable,
      BufferedEvent,
      $$BufferedEventsTableFilterComposer,
      $$BufferedEventsTableOrderingComposer,
      $$BufferedEventsTableAnnotationComposer,
      $$BufferedEventsTableCreateCompanionBuilder,
      $$BufferedEventsTableUpdateCompanionBuilder,
      (
        BufferedEvent,
        BaseReferences<
          _$DriftTelemetryBuffer,
          $BufferedEventsTable,
          BufferedEvent
        >,
      ),
      BufferedEvent,
      PrefetchHooks Function()
    >;

class $DriftTelemetryBufferManager {
  final _$DriftTelemetryBuffer _db;
  $DriftTelemetryBufferManager(this._db);
  $$BufferedEventsTableTableManager get bufferedEvents =>
      $$BufferedEventsTableTableManager(_db, _db.bufferedEvents);
}
