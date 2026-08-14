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
  @override
  List<GeneratedColumn> get $columns => [id, traceId];
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
    );
  }

  @override
  $BufferedEventsTable createAlias(String alias) {
    return $BufferedEventsTable(attachedDatabase, alias);
  }
}

class BufferedEvent extends DataClass implements Insertable<BufferedEvent> {
  /// Insertion order, which is the order a flush should send in — the wall
  /// clock on a device can move backwards.
  final int id;

  /// The send this event belongs to.
  final String traceId;
  const BufferedEvent({required this.id, required this.traceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trace_id'] = Variable<String>(traceId);
    return map;
  }

  BufferedEventsCompanion toCompanion(bool nullToAbsent) {
    return BufferedEventsCompanion(id: Value(id), traceId: Value(traceId));
  }

  factory BufferedEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BufferedEvent(
      id: serializer.fromJson<int>(json['id']),
      traceId: serializer.fromJson<String>(json['traceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'traceId': serializer.toJson<String>(traceId),
    };
  }

  BufferedEvent copyWith({int? id, String? traceId}) =>
      BufferedEvent(id: id ?? this.id, traceId: traceId ?? this.traceId);
  BufferedEvent copyWithCompanion(BufferedEventsCompanion data) {
    return BufferedEvent(
      id: data.id.present ? data.id.value : this.id,
      traceId: data.traceId.present ? data.traceId.value : this.traceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BufferedEvent(')
          ..write('id: $id, ')
          ..write('traceId: $traceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, traceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BufferedEvent &&
          other.id == this.id &&
          other.traceId == this.traceId);
}

class BufferedEventsCompanion extends UpdateCompanion<BufferedEvent> {
  final Value<int> id;
  final Value<String> traceId;
  const BufferedEventsCompanion({
    this.id = const Value.absent(),
    this.traceId = const Value.absent(),
  });
  BufferedEventsCompanion.insert({
    this.id = const Value.absent(),
    required String traceId,
  }) : traceId = Value(traceId);
  static Insertable<BufferedEvent> custom({
    Expression<int>? id,
    Expression<String>? traceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (traceId != null) 'trace_id': traceId,
    });
  }

  BufferedEventsCompanion copyWith({Value<int>? id, Value<String>? traceId}) {
    return BufferedEventsCompanion(
      id: id ?? this.id,
      traceId: traceId ?? this.traceId,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BufferedEventsCompanion(')
          ..write('id: $id, ')
          ..write('traceId: $traceId')
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
    BufferedEventsCompanion Function({Value<int> id, required String traceId});
typedef $$BufferedEventsTableUpdateCompanionBuilder =
    BufferedEventsCompanion Function({Value<int> id, Value<String> traceId});

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
              }) => BufferedEventsCompanion(id: id, traceId: traceId),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String traceId,
              }) => BufferedEventsCompanion.insert(id: id, traceId: traceId),
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
