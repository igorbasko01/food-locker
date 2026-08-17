import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';

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

    group('historyLast7Days', () {
      test('is empty when nothing is logged', () {
        expect(manager.historyLast7Days, isEmpty);
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

        final recent = manager.historyLast7Days;

        expect(recent.length, 7);
        expect(recent.first.value, 80.0);
        expect(recent.last.value, 86.0);
        expect(manager.history.length, 9);
      });

      test('excludes entries older than the window even when history is full', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        await manager.addWeight(
          DateTime(today.year, today.month, today.day - 30),
          90.0,
        );

        expect(manager.history, hasLength(1));
        expect(manager.historyLast7Days, isEmpty);
      });
    });

    group('WeightManager Overeating & Streak Stats', () {
      test('continuous weight loss increases clean streak', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final dayBefore = today.subtract(const Duration(days: 2));
        final threeDaysAgo = today.subtract(const Duration(days: 3));

        await manager.addWeight(threeDaysAgo, 80.0);
        await manager.addWeight(dayBefore, 79.0);
        await manager.addWeight(yesterday, 78.0);
        await manager.addWeight(today, 77.0);

        final stats = manager.overeatingStats;
        
        expect(stats.currentStreakType, StreakType.clean);
        expect(stats.currentStreakLength, 3);
        expect(stats.longestCleanStreakLength, 3);
      });

      test('continuous weight gain increases overeating streak', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final dayBefore = today.subtract(const Duration(days: 2));
        final threeDaysAgo = today.subtract(const Duration(days: 3));

        await manager.addWeight(threeDaysAgo, 80.0);
        await manager.addWeight(dayBefore, 81.0);
        await manager.addWeight(yesterday, 82.0);
        await manager.addWeight(today, 83.0);

        final stats = manager.overeatingStats;
        
        expect(stats.currentStreakType, StreakType.overeating);
        expect(stats.currentStreakLength, 3);
        expect(stats.longestCleanStreakLength, 0);
      });

      test('same weight is considered a clean day', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final dayBefore = today.subtract(const Duration(days: 2));

        await manager.addWeight(dayBefore, 80.0);
        await manager.addWeight(yesterday, 80.0);
        await manager.addWeight(today, 80.0);

        final stats = manager.overeatingStats;
        
        expect(stats.currentStreakType, StreakType.clean);
        expect(stats.currentStreakLength, 2);
        expect(stats.longestCleanStreakLength, 2);
      });

      test('missing today breaks the current streak', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final dayBefore = today.subtract(const Duration(days: 2));

        await manager.addWeight(dayBefore, 80.0);
        await manager.addWeight(yesterday, 79.0);
        // today weight is missing!

        final stats = manager.overeatingStats;
        
        expect(stats.currentStreakType, isNull);
        expect(stats.currentStreakLength, 0);
        // Longest clean streak is still 1 from dayBefore -> yesterday
        expect(stats.longestCleanStreakLength, 1);
      });
      
      test('missing a day in the middle breaks longest streak', () async {
        final today = DateTime.now();
        final twoDaysAgo = today.subtract(const Duration(days: 2));
        final threeDaysAgo = today.subtract(const Duration(days: 3));

        await manager.addWeight(threeDaysAgo, 80.0);
        await manager.addWeight(twoDaysAgo, 79.0);
        // yesterday is missing!
        await manager.addWeight(today, 78.0);

        final stats = manager.overeatingStats;
        
        expect(stats.currentStreakType, isNull);
        expect(stats.currentStreakLength, 0);
        // The streak from 3 days ago to 2 days ago is 1.
        expect(stats.longestCleanStreakLength, 1);
      });
    });
  });
}
