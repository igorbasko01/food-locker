import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_manager.dart';
import 'package:food_locker/features/bite/data/drift_bite_repository.dart';

/// Phase 4 verification: [BiteManager] logs bites through the repository and
/// keeps today's count consistent with the store. An in-memory drift database
/// stands in for the on-disk store, matching the repository tests.
void main() {
  late BiteDatabase db;
  late DriftBiteRepository repo;
  late BiteManager manager;

  setUp(() {
    db = BiteDatabase.forTesting(NativeDatabase.memory());
    repo = DriftBiteRepository(db);
    manager = BiteManager(repo);
  });

  tearDown(() async {
    await db.close();
  });

  test('todayCount starts at zero', () {
    expect(manager.todayCount, 0);
  });

  test('initialize loads today\'s existing count from the store', () async {
    // Two bites logged today, one logged yesterday — only today's should count.
    final now = DateTime.now();
    await repo.logBite(now);
    await repo.logBite(now);
    await repo.logBite(now.subtract(const Duration(days: 1)));

    await manager.initialize();

    expect(manager.todayCount, 2);
  });

  test('logBite records a bite and increments today\'s count', () async {
    await manager.initialize();
    expect(manager.todayCount, 0);

    await manager.logBite();
    expect(manager.todayCount, 1);

    await manager.logBite();
    expect(manager.todayCount, 2);

    // The taps are persisted, not just counted in memory.
    expect(await repo.lastBite(), isNotNull);
  });

  test('logBite notifies listeners', () async {
    var notifications = 0;
    manager.addListener(() => notifications++);

    await manager.logBite();

    expect(notifications, greaterThan(0));
  });
}
