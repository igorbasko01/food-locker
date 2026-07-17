import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/bite/data/drift_bite_repository.dart';
import 'package:food_locker/ui/pages/bite_analytics_page.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:food_locker/ui/widgets/stat_tile.dart';
import 'package:provider/provider.dart';

/// The stat tiles read against a seeded fixture, over a real in-memory Drift
/// store so the day-grouping query backs the numbers the tiles show.
void main() {
  late BiteDatabase db;
  late BiteRepository repo;

  setUp(() {
    db = BiteDatabase.forTesting(NativeDatabase.memory());
    repo = DriftBiteRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Logs [count] bites on [day], one per minute from 08:00.
  Future<void> logBites(DateTime day, int count) async {
    for (var i = 0; i < count; i++) {
      await repo.logBite(DateTime(day.year, day.month, day.day, 8, i));
    }
  }

  /// Logs [count] bites one per minute from [hour]:00 on [day] — a single
  /// cluster (consecutive-minute gaps stay under the meal-gap threshold).
  Future<void> logCluster(DateTime day, int hour, int count) async {
    for (var i = 0; i < count; i++) {
      await repo.logBite(DateTime(day.year, day.month, day.day, hour, i));
    }
  }

  Future<void> pumpPage(WidgetTester tester) async {
    // Pin the locale so the 30-day-max tile's date renders deterministically
    // (`shortDate` formats against the platform locale).
    tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    await tester.pumpWidget(
      Provider<BiteRepository>.value(
        value: repo,
        child: MaterialApp(theme: appTheme, home: const BiteAnalyticsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tiles read the averages and max from the seeded fixture', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final longAgo = DateTime(now.year, now.month, now.day - 100);

    // 30-day window: today 50 + yesterday 60 → average 55, max 60 (yesterday).
    // 1-year window also folds in the 80-bite day 100 days back → average 63.
    await logBites(today, 50);
    await logBites(yesterday, 60);
    await logBites(longAgo, 80);

    await pumpPage(tester);

    expect(
      find.descendant(
        of: find.widgetWithText(StatTile, '30-day average'),
        matching: find.text('55'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(StatTile, '1-year average'),
        matching: find.text('63'),
      ),
      findsOneWidget,
    );
    final maxTile = find.widgetWithText(StatTile, '30-day max');
    expect(
      find.descendant(of: maxTile, matching: find.text('60')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: maxTile,
        matching: find.text('${yesterday.month}/${yesterday.day}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tiles show a dash when no day qualifies', (tester) async {
    // A handful of bites today, all below the 40-bite average threshold and the
    // only bites ever logged → averages have no qualifying day, max is that day.
    final now = DateTime.now();
    await logBites(DateTime(now.year, now.month, now.day), 5);

    await pumpPage(tester);

    // Both average tiles read '—'; the max still surfaces the 5-bite day.
    expect(
      find.descendant(
        of: find.widgetWithText(StatTile, '30-day average'),
        matching: find.text('—'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(StatTile, '1-year average'),
        matching: find.text('—'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(StatTile, '30-day max'),
        matching: find.text('5'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('meal tiles read today\'s meals and the window average from a '
      'hand-counted fixture', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final earlier = DateTime(now.year, now.month, now.day - 3);

    // Today: two meals (12 bites @ 08, 15 @ 09) plus a 5-bite snack @ 10 that
    // stays below minMealBites → 2 meals.
    await logCluster(today, 8, 12);
    await logCluster(today, 9, 15);
    await logCluster(today, 10, 5);
    // Yesterday: a single 20-bite meal.
    await logCluster(yesterday, 8, 20);
    // Three days ago: 8 bites — a snack, so a logged day with 0 meals.
    await logCluster(earlier, 8, 8);
    // Days with bites in the window: 3; meals 2 + 1 + 0 = 3 → average 1.0.
    // Meal sizes 12, 15, 20 → (47 / 3) = 15.67 → 16 (snacks excluded).

    await pumpPage(tester);

    expect(
      find.descendant(
        of: find.widgetWithText(StatTile, 'Meals today'),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(StatTile, '30-day avg meals'),
        matching: find.text('1.0'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(StatTile, '30-day avg meal size'),
        matching: find.text('16'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('meal breakdown card lists today\'s meals and snack total', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Today: two meals (12 @ 08, 15 @ 09) plus a 5-bite snack @ 10.
    await logCluster(today, 8, 12);
    await logCluster(today, 9, 15);
    await logCluster(today, 10, 5);

    await pumpPage(tester);
    // The breakdown card is the bottom card in the scroll view; build it.
    await tester.scrollUntilVisible(find.text('Today\'s meals'), 200);

    expect(find.text('Today\'s meals'), findsOneWidget);
    expect(find.text('Meal 1'), findsOneWidget);
    expect(find.text('Meal 2'), findsOneWidget);
    expect(find.text('12 bites'), findsOneWidget);
    expect(find.text('15 bites'), findsOneWidget);
    expect(find.text('Snacks'), findsOneWidget);
    expect(find.text('5 bites'), findsOneWidget);
  });

  testWidgets('meal breakdown card shows its empty state when today is empty '
      'but earlier days have bites', (tester) async {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    // Bites only on yesterday: the page has data, but today is empty.
    await logCluster(yesterday, 8, 20);

    await pumpPage(tester);
    await tester.scrollUntilVisible(find.text('Today\'s meals'), 200);

    expect(find.text('Today\'s meals'), findsOneWidget);
    expect(find.text('No bites logged today yet.'), findsOneWidget);
    expect(find.text('Snacks'), findsNothing);
  });
}
