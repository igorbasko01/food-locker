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

abstract class _$BiteDatabase extends GeneratedDatabase {
  _$BiteDatabase(QueryExecutor e) : super(e);
  $BiteDatabaseManager get managers => $BiteDatabaseManager(this);
  late final $BitesTable bites = $BitesTable(this);
  late final Index idxBitesAtMs = Index(
    'idx_bites_at_ms',
    'CREATE INDEX idx_bites_at_ms ON bites (at_ms)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [bites, idxBitesAtMs];
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

class $BiteDatabaseManager {
  final _$BiteDatabase _db;
  $BiteDatabaseManager(this._db);
  $$BitesTableTableManager get bites =>
      $$BitesTableTableManager(_db, _db.bites);
}
