import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';

/// Phase 1 verification: the Drift database opens and a bite row round-trips.
void main() {
  late BiteDatabase db;

  setUp(() {
    db = BiteDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('a bite row round-trips through the database', () async {
    final atMs = DateTime(2026, 7, 13, 12, 30, 45, 123).millisecondsSinceEpoch;

    final id = await db
        .into(db.bites)
        .insert(BitesCompanion.insert(atMs: atMs));

    final rows = await db.select(db.bites).get();

    expect(rows, hasLength(1));
    expect(rows.single.id, id);
    expect(rows.single.atMs, atMs);
  });

  test('at_ms preserves millisecond precision', () async {
    // The whole point of storing epoch millis as a plain integer: no silent
    // truncation to whole seconds.
    final atMs = DateTime(2026, 7, 13, 0, 0, 0, 789).millisecondsSinceEpoch;
    expect(atMs % 1000, 789);

    await db.into(db.bites).insert(BitesCompanion.insert(atMs: atMs));

    final stored = await db.select(db.bites).getSingle();
    expect(stored.atMs, atMs);
    expect(stored.atMs % 1000, 789);
  });

  test('ids autoincrement in chronological (insertion) order', () async {
    final first = await db
        .into(db.bites)
        .insert(BitesCompanion.insert(atMs: 1000));
    final second = await db
        .into(db.bites)
        .insert(BitesCompanion.insert(atMs: 2000));

    expect(second, greaterThan(first));
  });
}
