import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/date_range.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';
import 'package:food_locker/features/weight/data/weight.dart';

void main() {
  group('WeightManager Statistics', () {
    late WeightManager manager;
    late InMemoryWeightRepository repository;

    setUp(() {
      repository = InMemoryWeightRepository();
      manager = WeightManager(repository);
    });

    test('lowestAllTime returns null when empty', () {
      expect(manager.lowestAllTime, isNull);
    });

    test('lowestAllTime returns global minimum', () async {
      await manager.addWeight(DateTime(2023, 1, 1), 80.0);
      await manager.addWeight(DateTime(2023, 2, 1), 75.0);
      await manager.addWeight(DateTime(2023, 3, 1), 77.0);

      expect(manager.lowestAllTime, 75.0);
    });

    test('lowestLast7Days returns minimum from recent week', () async {
      final now = DateTime.now();
      
      // Outside 7 days
      await manager.addWeight(now.subtract(const Duration(days: 10)), 70.0);
      
      // Within 7 days
      await manager.addWeight(now.subtract(const Duration(days: 5)), 75.0);
      await manager.addWeight(now.subtract(const Duration(days: 2)), 72.0);

      expect(manager.lowestLast7Days, 72.0);
    });

    test('lowestLast30Days returns minimum from recent month', () async {
      final now = DateTime.now();
      
      // Outside 30 days
      await manager.addWeight(now.subtract(const Duration(days: 40)), 65.0);
      
      // Within 30 days but outside 7 days
      await manager.addWeight(now.subtract(const Duration(days: 15)), 68.0);
      
      // Within 7 days
      await manager.addWeight(now.subtract(const Duration(days: 5)), 70.0);

      expect(manager.lowestLast30Days, 68.0);
      expect(manager.lowestLast7Days, 70.0);
      expect(manager.lowestAllTime, 65.0);
    });

    group('history', () {
      test('is empty when nothing is logged', () {
        expect(manager.history, isEmpty);
      });

      test('keeps the 7 calendar days ending today, newest first', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        for (var daysAgo = 0; daysAgo <= 8; daysAgo++) {
          await manager.addWeight(
            DateTime(today.year, today.month, today.day - daysAgo),
            80.0 + daysAgo,
          );
        }

        final history = manager.history;

        expect(history.length, 7);
        expect(history.first.value, 80.0);
        expect(history.last.value, 86.0);
        expect(repository.getAllWeights().length, 9);
      });

      test('drops entries older than the window', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        await manager.addWeight(
          DateTime(today.year, today.month, today.day - 30),
          90.0,
        );

        expect(repository.getAllWeights(), hasLength(1));
        expect(manager.history, isEmpty);
      });

      test('starts on the 7-day range', () {
        expect(manager.historyRange, const DateRange.lastDays(7));
      });

      test('selecting a wider range brings older entries back', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        await manager.addWeight(today, 75.0);
        await manager.addWeight(
          DateTime(today.year, today.month, today.day - 20),
          78.0,
        );

        expect(manager.history.map((w) => w.value), [75.0]);

        var notified = 0;
        manager.addListener(() => notified++);
        manager.selectHistoryRange(const DateRange.lastDays(30));

        expect(manager.historyRange, const DateRange.lastDays(30));
        expect(manager.history.map((w) => w.value), [75.0, 78.0]);
        expect(notified, 1);
      });

      test('selecting a narrower range drops the entries outside it', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        manager.selectHistoryRange(const DateRange.lastDays(365));
        await manager.addWeight(today, 75.0);
        await manager.addWeight(
          DateTime(today.year, today.month - 3, today.day),
          79.0,
        );

        expect(manager.history, hasLength(2));

        manager.selectHistoryRange(const DateRange.lastDays(7));

        expect(manager.history.map((w) => w.value), [75.0]);
      });

      test('re-selecting the current range does not notify', () {
        var notified = 0;
        manager.addListener(() => notified++);

        manager.selectHistoryRange(const DateRange.lastDays(7));

        expect(notified, 0);
      });

      test('initialize loads the window from the repository', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        await repository.saveWeight(Weight(date: today, value: 75.0));
        await repository.saveWeight(
          Weight(
            date: DateTime(today.year, today.month, today.day - 10),
            value: 78.0,
          ),
        );

        await manager.initialize();

        expect(manager.history.map((w) => w.value), [75.0]);
      });
    });
  });

  group('WeightManager refresh', () {
    test('picks up entries written straight to the repository', () async {
      final repository = InMemoryWeightRepository();
      final manager = WeightManager(repository);
      await manager.initialize();

      // What a restore does: writes through the repository, never through the
      // manager.
      await repository.saveWeight(Weight(date: DateTime.now(), value: 71.5));
      expect(manager.history, isEmpty);

      await manager.refresh();

      expect(manager.history.single.value, 71.5);
    });

    test('drops entries the repository no longer holds', () async {
      final repository = InMemoryWeightRepository();
      final manager = WeightManager(repository);
      await manager.addWeight(DateTime.now(), 80.0);
      expect(manager.history, hasLength(1));

      await repository.clear();
      await manager.refresh();

      expect(manager.history, isEmpty);
    });

    test('notifies listeners so the tab rebuilds', () async {
      final repository = InMemoryWeightRepository();
      final manager = WeightManager(repository);
      var notifications = 0;
      manager.addListener(() => notifications++);

      await manager.refresh();

      expect(notifications, 1);
    });
  });
}
