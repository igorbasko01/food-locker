import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/bite/data/drift_bite_repository.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:food_locker/ui/pages/bite_analytics_page.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:food_locker/ui/widgets/stat_tile.dart';
import 'package:provider/provider.dart';

/// The stat tiles read against a seeded fixture, over a real in-memory Drift
/// store so the day-grouping query backs the numbers the tiles show.
void main() {
  late BiteDatabase db;
  late BiteRepository repo;
  late InMemoryWeightRepository weightRepo;

  setUp(() {
    db = BiteDatabase.forTesting(NativeDatabase.memory());
    repo = DriftBiteRepository(db);
    weightRepo = InMemoryWeightRepository();
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

  /// Drives the daily-bites chart's tap callback for the bar at [groupIndex],
  /// as fl_chart would on a tap-up — the canvas bars can't be tapped by
  /// coordinate reliably, so we invoke the wired callback directly.
  void tapBar(WidgetTester tester, int groupIndex) {
    final data = tester.widget<BarChart>(find.byType(BarChart)).data;
    final group = data.barGroups[groupIndex];
    data.barTouchData.touchCallback!(
      FlTapUpEvent(TapUpDetails(kind: PointerDeviceKind.touch)),
      BarTouchResponse(
        touchLocation: Offset.zero,
        touchChartCoordinate: Offset.zero,
        spot: BarTouchedSpot(
          group,
          groupIndex,
          group.barRods.first,
          0,
          null,
          -1,
          const FlSpot(0, 0),
          Offset.zero,
        ),
      ),
    );
  }

  Future<void> pumpPage(WidgetTester tester) async {
    // Pin the locale so the 30-day-max tile's date renders deterministically
    // (`shortDate` formats against the platform locale).
    tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<BiteRepository>.value(value: repo),
          Provider<WeightRepository>.value(value: weightRepo),
        ],
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
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('32 bites'), findsOneWidget);
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

  testWidgets('meal breakdown card shows the selected day\'s body weight, and '
      'follows a tapped bar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    await logCluster(today, 8, 12);
    await logCluster(yesterday, 9, 20);
    await weightRepo.saveWeight(Weight(date: today, value: 80.4));
    await weightRepo.saveWeight(
      Weight(date: yesterday, value: 81.2, unit: WeightUnit.pounds),
    );

    await pumpPage(tester);

    expect(find.text('80.4 kg'), findsOneWidget);

    // Bar 0 is yesterday: the line follows the selection, in that day's unit.
    tapBar(tester, 0);
    await tester.pumpAndSettle();

    expect(find.text('81.2 lbs'), findsOneWidget);
    expect(find.text('80.4 kg'), findsNothing);
  });

  testWidgets('meal breakdown card marks a day with no weigh-in', (
    tester,
  ) async {
    final now = DateTime.now();
    await logCluster(DateTime(now.year, now.month, now.day), 8, 12);

    await pumpPage(tester);
    await tester.scrollUntilVisible(find.text('Today\'s meals'), 200);

    expect(find.text('No weigh-in'), findsOneWidget);
  });

  testWidgets('tapping a bar switches the breakdown card to that day, and '
      '"Back to today" returns to today', (tester) async {
    // A tall surface so the whole scroll view builds — the breakdown card and
    // the chart are both on-screen, so no scrolling is needed between tapping a
    // bar and reading the card.
    await tester.binding.setSurfaceSize(const Size(600, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    // Today: a 12-bite meal. Yesterday: a 20-bite meal. Two bars: index 0 is
    // the earlier day (yesterday), index 1 is today.
    await logCluster(today, 8, 12);
    await logCluster(yesterday, 9, 20);

    await pumpPage(tester);

    // Defaults to today: card titled "Today's meals", showing today's meal, no
    // back control.
    expect(find.text('Today\'s meals'), findsOneWidget);
    expect(find.text('Back to today'), findsNothing);
    // The meal row and the day's total, which the lone meal accounts for.
    expect(find.text('12 bites'), findsNWidgets(2));

    // Tap yesterday's bar → card follows it: back control appears, the today
    // title gives way to yesterday's date, and its 20-bite meal shows.
    tapBar(tester, 0);
    await tester.pumpAndSettle();

    expect(find.text('Today\'s meals'), findsNothing);
    expect(find.text(fullDate(yesterday)), findsOneWidget);
    expect(find.text('Back to today'), findsOneWidget);
    expect(find.text('20 bites'), findsNWidgets(2));

    // Back to today resets the card.
    await tester.tap(find.text('Back to today'));
    await tester.pumpAndSettle();

    expect(find.text('Today\'s meals'), findsOneWidget);
    expect(find.text('Back to today'), findsNothing);
    expect(find.text('12 bites'), findsNWidgets(2));
  });
}
