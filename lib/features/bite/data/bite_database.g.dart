// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bite_database.dart';

// ignore_for_file: type=lint
class $BitesTable extends Bites with TableInfo<$BitesTable, Bite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BitesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _atMsMeta = const VerificationMeta('atMs');
  @override
  late final GeneratedColumn<int> atMs = GeneratedColumn<int>(
    'at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, atMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at_ms')) {
      context.handle(
        _atMsMeta,
        atMs.isAcceptableOrUnknown(data['at_ms']!, _atMsMeta),
      );
    } else if (isInserting) {
      context.missing(_atMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bite(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      atMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at_ms'],
      )!,
    );
  }

  @override
  $BitesTable createAlias(String alias) {
    return $BitesTable(attachedDatabase, alias);
  }
}

class Bite extends DataClass implements Insertable<Bite> {
  /// Insertion order is chronological (append-only), so the autoincrement id
  /// doubles as a stable chronological key.
  final int id;

  /// Epoch milliseconds (a UTC instant), millisecond precision.
  ///
  /// Deliberately a plain [integer], not drift's `dateTime()`: the default
  /// datetime mode stores unix *seconds* and would silently truncate the
  /// millisecond precision the inter-bite deltas depend on. Integer epoch
  /// millis keep deltas an exact subtraction and stay DST-safe (monotonic
  /// across midnight and clock changes).
  final int atMs;
  const Bite({required this.id, required this.atMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at_ms'] = Variable<int>(atMs);
    return map;
  }

  BitesCompanion toCompanion(bool nullToAbsent) {
    return BitesCompanion(id: Value(id), atMs: Value(atMs));
  }

  factory Bite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bite(
      id: serializer.fromJson<int>(json['id']),
      atMs: serializer.fromJson<int>(json['atMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'atMs': serializer.toJson<int>(atMs),
    };
  }

  Bite copyWith({int? id, int? atMs}) =>
      Bite(id: id ?? this.id, atMs: atMs ?? this.atMs);
  Bite copyWithCompanion(BitesCompanion data) {
    return Bite(
      id: data.id.present ? data.id.value : this.id,
      atMs: data.atMs.present ? data.atMs.value : this.atMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bite(')
          ..write('id: $id, ')
          ..write('atMs: $atMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, atMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bite && other.id == this.id && other.atMs == this.atMs);
}

class BitesCompanion extends UpdateCompanion<Bite> {
  final Value<int> id;
  final Value<int> atMs;
  const BitesCompanion({
    this.id = const Value.absent(),
    this.atMs = const Value.absent(),
  });
  BitesCompanion.insert({this.id = const Value.absent(), required int atMs})
    : atMs = Value(atMs);
  static Insertable<Bite> custom({Expression<int>? id, Expression<int>? atMs}) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (atMs != null) 'at_ms': atMs,
    });
  }

  BitesCompanion copyWith({Value<int>? id, Value<int>? atMs}) {
    return BitesCompanion(id: id ?? this.id, atMs: atMs ?? this.atMs);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (atMs.present) {
      map['at_ms'] = Variable<int>(atMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BitesCompanion(')
          ..write('id: $id, ')
          ..write('atMs: $atMs')
          ..write(')'))
        .toString();
  }
}

class $PacingConfigsTable extends PacingConfigs
    with TableInfo<$PacingConfigsTable, PacingConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PacingConfigsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _effectiveMsMeta = const VerificationMeta(
    'effectiveMs',
  );
  @override
  late final GeneratedColumn<int> effectiveMs = GeneratedColumn<int>(
    'effective_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _b1SMeta = const VerificationMeta('b1S');
  @override
  late final GeneratedColumn<int> b1S = GeneratedColumn<int>(
    'b1_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _b2SMeta = const VerificationMeta('b2S');
  @override
  late final GeneratedColumn<int> b2S = GeneratedColumn<int>(
    'b2_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, effectiveMs, b1S, b2S];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pacing_config';
  @override
  VerificationContext validateIntegrity(
    Insertable<PacingConfig> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('effective_ms')) {
      context.handle(
        _effectiveMsMeta,
        effectiveMs.isAcceptableOrUnknown(
          data['effective_ms']!,
          _effectiveMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveMsMeta);
    }
    if (data.containsKey('b1_s')) {
      context.handle(
        _b1SMeta,
        b1S.isAcceptableOrUnknown(data['b1_s']!, _b1SMeta),
      );
    } else if (isInserting) {
      context.missing(_b1SMeta);
    }
    if (data.containsKey('b2_s')) {
      context.handle(
        _b2SMeta,
        b2S.isAcceptableOrUnknown(data['b2_s']!, _b2SMeta),
      );
    } else if (isInserting) {
      context.missing(_b2SMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PacingConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PacingConfig(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      effectiveMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}effective_ms'],
      )!,
      b1S: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}b1_s'],
      )!,
      b2S: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}b2_s'],
      )!,
    );
  }

  @override
  $PacingConfigsTable createAlias(String alias) {
    return $PacingConfigsTable(attachedDatabase, alias);
  }
}

class PacingConfig extends DataClass implements Insertable<PacingConfig> {
  final int id;

  /// Epoch millis (a UTC instant): the moment this config version took effect.
  final int effectiveMs;

  /// End of the "too soon" zone, in seconds. `[0, b1)` is too soon.
  final int b1S;

  /// Start of the "in the clear" zone, in seconds — the point at which biting
  /// is recommended and the haptic fires. `[b1, b2)` is "ok — hold on",
  /// `[b2, ∞)` is "in the clear". Derived boundary, stored so past bites stay
  /// reconstructable.
  final int b2S;
  const PacingConfig({
    required this.id,
    required this.effectiveMs,
    required this.b1S,
    required this.b2S,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['effective_ms'] = Variable<int>(effectiveMs);
    map['b1_s'] = Variable<int>(b1S);
    map['b2_s'] = Variable<int>(b2S);
    return map;
  }

  PacingConfigsCompanion toCompanion(bool nullToAbsent) {
    return PacingConfigsCompanion(
      id: Value(id),
      effectiveMs: Value(effectiveMs),
      b1S: Value(b1S),
      b2S: Value(b2S),
    );
  }

  factory PacingConfig.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PacingConfig(
      id: serializer.fromJson<int>(json['id']),
      effectiveMs: serializer.fromJson<int>(json['effectiveMs']),
      b1S: serializer.fromJson<int>(json['b1S']),
      b2S: serializer.fromJson<int>(json['b2S']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'effectiveMs': serializer.toJson<int>(effectiveMs),
      'b1S': serializer.toJson<int>(b1S),
      'b2S': serializer.toJson<int>(b2S),
    };
  }

  PacingConfig copyWith({int? id, int? effectiveMs, int? b1S, int? b2S}) =>
      PacingConfig(
        id: id ?? this.id,
        effectiveMs: effectiveMs ?? this.effectiveMs,
        b1S: b1S ?? this.b1S,
        b2S: b2S ?? this.b2S,
      );
  PacingConfig copyWithCompanion(PacingConfigsCompanion data) {
    return PacingConfig(
      id: data.id.present ? data.id.value : this.id,
      effectiveMs: data.effectiveMs.present
          ? data.effectiveMs.value
          : this.effectiveMs,
      b1S: data.b1S.present ? data.b1S.value : this.b1S,
      b2S: data.b2S.present ? data.b2S.value : this.b2S,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PacingConfig(')
          ..write('id: $id, ')
          ..write('effectiveMs: $effectiveMs, ')
          ..write('b1S: $b1S, ')
          ..write('b2S: $b2S')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, effectiveMs, b1S, b2S);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PacingConfig &&
          other.id == this.id &&
          other.effectiveMs == this.effectiveMs &&
          other.b1S == this.b1S &&
          other.b2S == this.b2S);
}

class PacingConfigsCompanion extends UpdateCompanion<PacingConfig> {
  final Value<int> id;
  final Value<int> effectiveMs;
  final Value<int> b1S;
  final Value<int> b2S;
  const PacingConfigsCompanion({
    this.id = const Value.absent(),
    this.effectiveMs = const Value.absent(),
    this.b1S = const Value.absent(),
    this.b2S = const Value.absent(),
  });
  PacingConfigsCompanion.insert({
    this.id = const Value.absent(),
    required int effectiveMs,
    required int b1S,
    required int b2S,
  }) : effectiveMs = Value(effectiveMs),
       b1S = Value(b1S),
       b2S = Value(b2S);
  static Insertable<PacingConfig> custom({
    Expression<int>? id,
    Expression<int>? effectiveMs,
    Expression<int>? b1S,
    Expression<int>? b2S,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (effectiveMs != null) 'effective_ms': effectiveMs,
      if (b1S != null) 'b1_s': b1S,
      if (b2S != null) 'b2_s': b2S,
    });
  }

  PacingConfigsCompanion copyWith({
    Value<int>? id,
    Value<int>? effectiveMs,
    Value<int>? b1S,
    Value<int>? b2S,
  }) {
    return PacingConfigsCompanion(
      id: id ?? this.id,
      effectiveMs: effectiveMs ?? this.effectiveMs,
      b1S: b1S ?? this.b1S,
      b2S: b2S ?? this.b2S,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (effectiveMs.present) {
      map['effective_ms'] = Variable<int>(effectiveMs.value);
    }
    if (b1S.present) {
      map['b1_s'] = Variable<int>(b1S.value);
    }
    if (b2S.present) {
      map['b2_s'] = Variable<int>(b2S.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PacingConfigsCompanion(')
          ..write('id: $id, ')
          ..write('effectiveMs: $effectiveMs, ')
          ..write('b1S: $b1S, ')
          ..write('b2S: $b2S')
          ..write(')'))
        .toString();
  }
}

abstract class _$BiteDatabase extends GeneratedDatabase {
  _$BiteDatabase(QueryExecutor e) : super(e);
  $BiteDatabaseManager get managers => $BiteDatabaseManager(this);
  late final $BitesTable bites = $BitesTable(this);
  late final Index idxBitesAtMs = Index(
    'idx_bites_at_ms',
    'CREATE INDEX idx_bites_at_ms ON bites (at_ms)',
  );
  late final $PacingConfigsTable pacingConfigs = $PacingConfigsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bites,
    idxBitesAtMs,
    pacingConfigs,
  ];
}

typedef $$BitesTableCreateCompanionBuilder =
    BitesCompanion Function({Value<int> id, required int atMs});
typedef $$BitesTableUpdateCompanionBuilder =
    BitesCompanion Function({Value<int> id, Value<int> atMs});

class $$BitesTableFilterComposer extends Composer<_$BiteDatabase, $BitesTable> {
  $$BitesTableFilterComposer({
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

  ColumnFilters<int> get atMs => $composableBuilder(
    column: $table.atMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BitesTableOrderingComposer
    extends Composer<_$BiteDatabase, $BitesTable> {
  $$BitesTableOrderingComposer({
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

  ColumnOrderings<int> get atMs => $composableBuilder(
    column: $table.atMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BitesTableAnnotationComposer
    extends Composer<_$BiteDatabase, $BitesTable> {
  $$BitesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get atMs =>
      $composableBuilder(column: $table.atMs, builder: (column) => column);
}

class $$BitesTableTableManager
    extends
        RootTableManager<
          _$BiteDatabase,
          $BitesTable,
          Bite,
          $$BitesTableFilterComposer,
          $$BitesTableOrderingComposer,
          $$BitesTableAnnotationComposer,
          $$BitesTableCreateCompanionBuilder,
          $$BitesTableUpdateCompanionBuilder,
          (Bite, BaseReferences<_$BiteDatabase, $BitesTable, Bite>),
          Bite,
          PrefetchHooks Function()
        > {
  $$BitesTableTableManager(_$BiteDatabase db, $BitesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BitesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BitesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BitesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> atMs = const Value.absent(),
              }) => BitesCompanion(id: id, atMs: atMs),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required int atMs}) =>
                  BitesCompanion.insert(id: id, atMs: atMs),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BitesTableProcessedTableManager =
    ProcessedTableManager<
      _$BiteDatabase,
      $BitesTable,
      Bite,
      $$BitesTableFilterComposer,
      $$BitesTableOrderingComposer,
      $$BitesTableAnnotationComposer,
      $$BitesTableCreateCompanionBuilder,
      $$BitesTableUpdateCompanionBuilder,
      (Bite, BaseReferences<_$BiteDatabase, $BitesTable, Bite>),
      Bite,
      PrefetchHooks Function()
    >;

typedef $$PacingConfigsTableCreateCompanionBuilder =
    PacingConfigsCompanion Function({
      Value<int> id,
      required int effectiveMs,
      required int b1S,
      required int b2S,
    });
typedef $$PacingConfigsTableUpdateCompanionBuilder =
    PacingConfigsCompanion Function({
      Value<int> id,
      Value<int> effectiveMs,
      Value<int> b1S,
      Value<int> b2S,
    });

class $$PacingConfigsTableFilterComposer
    extends Composer<_$BiteDatabase, $PacingConfigsTable> {
  $$PacingConfigsTableFilterComposer({
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

  ColumnFilters<int> get effectiveMs => $composableBuilder(
    column: $table.effectiveMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get b1S => $composableBuilder(
    column: $table.b1S,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get b2S => $composableBuilder(
    column: $table.b2S,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PacingConfigsTableOrderingComposer
    extends Composer<_$BiteDatabase, $PacingConfigsTable> {
  $$PacingConfigsTableOrderingComposer({
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

  ColumnOrderings<int> get effectiveMs => $composableBuilder(
    column: $table.effectiveMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get b1S => $composableBuilder(
    column: $table.b1S,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get b2S => $composableBuilder(
    column: $table.b2S,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PacingConfigsTableAnnotationComposer
    extends Composer<_$BiteDatabase, $PacingConfigsTable> {
  $$PacingConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get effectiveMs => $composableBuilder(
    column: $table.effectiveMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get b1S =>
      $composableBuilder(column: $table.b1S, builder: (column) => column);

  GeneratedColumn<int> get b2S =>
      $composableBuilder(column: $table.b2S, builder: (column) => column);
}

class $$PacingConfigsTableTableManager
    extends
        RootTableManager<
          _$BiteDatabase,
          $PacingConfigsTable,
          PacingConfig,
          $$PacingConfigsTableFilterComposer,
          $$PacingConfigsTableOrderingComposer,
          $$PacingConfigsTableAnnotationComposer,
          $$PacingConfigsTableCreateCompanionBuilder,
          $$PacingConfigsTableUpdateCompanionBuilder,
          (
            PacingConfig,
            BaseReferences<
              _$BiteDatabase,
              $PacingConfigsTable,
              PacingConfig
            >,
          ),
          PacingConfig,
          PrefetchHooks Function()
        > {
  $$PacingConfigsTableTableManager(_$BiteDatabase db, $PacingConfigsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PacingConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PacingConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PacingConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> effectiveMs = const Value.absent(),
                Value<int> b1S = const Value.absent(),
                Value<int> b2S = const Value.absent(),
              }) => PacingConfigsCompanion(
                id: id,
                effectiveMs: effectiveMs,
                b1S: b1S,
                b2S: b2S,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int effectiveMs,
                required int b1S,
                required int b2S,
              }) => PacingConfigsCompanion.insert(
                id: id,
                effectiveMs: effectiveMs,
                b1S: b1S,
                b2S: b2S,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PacingConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$BiteDatabase,
      $PacingConfigsTable,
      PacingConfig,
      $$PacingConfigsTableFilterComposer,
      $$PacingConfigsTableOrderingComposer,
      $$PacingConfigsTableAnnotationComposer,
      $$PacingConfigsTableCreateCompanionBuilder,
      $$PacingConfigsTableUpdateCompanionBuilder,
      (
        PacingConfig,
        BaseReferences<_$BiteDatabase, $PacingConfigsTable, PacingConfig>,
      ),
      PacingConfig,
      PrefetchHooks Function()
    >;

class $BiteDatabaseManager {
  final _$BiteDatabase _db;
  $BiteDatabaseManager(this._db);
  $$BitesTableTableManager get bites =>
      $$BitesTableTableManager(_db, _db.bites);
  $$PacingConfigsTableTableManager get pacingConfigs =>
      $$PacingConfigsTableTableManager(_db, _db.pacingConfigs);
}
