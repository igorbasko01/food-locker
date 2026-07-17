import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_analytics_controller.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/bite/data/drift_bite_repository.dart';

/// [BiteAnalyticsController] over an in-memory Drift store, covering the
/// pickable breakdown day: `load` seeds today, `selectDay` re-queries another
/// day, and `isSelectedDayToday` tracks whether the card is on today.
void main() {
  late BiteDatabase db;
  late BiteRepository repo;
  late BiteAnalyticsController controller;

  setUp(() {
    db = BiteDatabase.forTesting(NativeDatabase.memory());
    repo = DriftBiteRepository(db);
    controller = BiteAnalyticsController(repo);
  });

  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  /// Logs [count] bites one per minute from [hour]:00 on [day] — a single
  /// cluster (consecutive-minute gaps stay under the meal-gap threshold).
  Future<void> logCluster(DateTime day, int hour, int count) async {
    for (var i = 0; i < count; i++) {
      await repo.logBite(DateTime(day.year, day.month, day.day, hour, i));
    }
  }

  test('load seeds the selected day to today and its breakdown', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await logCluster(today, 8, 12);

    await controller.load();

    expect(controller.selectedDay, today);
    expect(controller.isSelectedDayToday, isTrue);
    expect(controller.selectedBreakdown.meals, hasLength(1));
    expect(controller.selectedBreakdown.meals.single.count, 12);
  });

  test('selectDay loads the chosen day\'s breakdown and flips '
      'isSelectedDayToday', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    await logCluster(today, 8, 12);
    await logCluster(yesterday, 9, 20);

    await controller.load();
    expect(controller.isSelectedDayToday, isTrue);

    await controller.selectDay(yesterday);

    expect(controller.selectedDay, yesterday);
    expect(controller.isSelectedDayToday, isFalse);
    expect(controller.selectedBreakdown.meals, hasLength(1));
    expect(controller.selectedBreakdown.meals.single.count, 20);

    // Back to today re-selects today and its breakdown.
    await controller.selectDay(today);
    expect(controller.isSelectedDayToday, isTrue);
    expect(controller.selectedBreakdown.meals.single.count, 12);
  });

  test('selectDay normalises a timestamp to local midnight', () async {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    await logCluster(yesterday, 9, 20);

    await controller.load();
    await controller.selectDay(DateTime(now.year, now.month, now.day - 1, 15, 30));

    expect(controller.selectedDay, yesterday);
  });

  test('selecting another day leaves the today metrics untouched', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    // Today: one meal. Yesterday: two meals.
    await logCluster(today, 8, 12);
    await logCluster(yesterday, 8, 15);
    await logCluster(yesterday, 10, 20);

    await controller.load();
    expect(controller.mealsToday, 1);

    await controller.selectDay(yesterday);

    // The breakdown follows the selection, but "meals today" stays a today
    // metric.
    expect(controller.selectedBreakdown.meals, hasLength(2));
    expect(controller.mealsToday, 1);
  });
}
