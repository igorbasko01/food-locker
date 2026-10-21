import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/hive_weight_entry.dart';
import 'package:food_locker/hive_registrar.g.dart';
import 'package:hive_ce/hive.dart';

/// Runtime verification of the Hive → Hive CE migration.
///
/// The rest of the suite runs on in-memory Hive boxes, so it never reads a box
/// back from disk through the generated [HiveWeightEntryAdapter]'s binary
/// serialization. These tests open a real box on disk to prove the migrated
/// adapters register and round-trip correctly.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_ce_test');
    Hive.init(tempDir.path);
    // The adapter registry is global and survives across tests in this isolate,
    // so only register on the first setUp. Guarding on one typeId is enough
    // because registerAdapters() registers both together.
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapters();
    }
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('registerAdapters registers the Weight adapters by their typeIds', () {
    // typeIds are the on-disk contract; they must not drift across the
    // migration or existing boxes become unreadable.
    expect(Hive.isAdapterRegistered(4), isTrue, reason: 'HiveWeightEntryAdapter');
    expect(Hive.isAdapterRegistered(3), isTrue, reason: 'WeightUnitAdapter');
  });

  test('a HiveWeightEntry round-trips through a real on-disk box', () async {
    final box = await Hive.openBox<HiveWeightEntry>('weights');
    final date = DateTime(2026, 7, 13);
    await box.put('2026-7-13', HiveWeightEntry(date: date, kilograms: 82.5, unit: WeightUnit.pounds));

    // Close and reopen to force a read back from disk through the adapter.
    await box.close();
    final reopened = await Hive.openBox<HiveWeightEntry>('weights');
    final stored = reopened.get('2026-7-13');

    expect(stored, isNotNull);
    expect(stored!.date, date);
    expect(stored.kilograms, 82.5);
    expect(stored.unit, WeightUnit.pounds);
  });

  test('a HiveWeightEntry persists its default unit through the adapter', () async {
    final box = await Hive.openBox<HiveWeightEntry>('weights');
    await box.put('d', HiveWeightEntry(date: DateTime(2026, 1, 1), kilograms: 70));

    await box.close();
    final reopened = await Hive.openBox<HiveWeightEntry>('weights');
    expect(reopened.get('d')!.unit, WeightUnit.kilograms);
  });
}
