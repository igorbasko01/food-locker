import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/core/date_range.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/settings/data/in_memory_settings_repository.dart';
import 'package:food_locker/features/settings/data/settings_manager.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/ui/pages/weight_page.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:food_locker/ui/widgets/history_range_selector.dart';
import 'package:food_locker/ui/widgets/stat_tile.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester,
    WeightManager manager, {
    MeasurementSystem system = MeasurementSystem.metric,
  }) async {
    // The chart's 1.5 aspect ratio pushes the heading and the history list
    // below the fold on the default 800x600 surface, so they never get built.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<WeightManager>.value(value: manager),
            ChangeNotifierProvider<SettingsManager>(
              create: (_) => SettingsManager(
                InMemorySettingsRepository(measurementSystem: system),
              ),
            ),
          ],
          child: const WeightPage(),
        ),
      ),
    );
  }

  /// A weigh-in every day for the last 28, shedding [dailyLoss] kg a day and
  /// landing on 70.0 today — enough to fill both complete week windows and the
  /// whole 30-day regression, whichever weekday the suite runs on. A negative
  /// [dailyLoss] ramps the other way.
  Future<WeightManager> rampedManager(double dailyLoss) async {
    final manager = WeightManager(InMemoryWeightRepository());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (var daysAgo = 0; daysAgo < 28; daysAgo++) {
      await manager.addWeight(
        DateTime(today.year, today.month, today.day - daysAgo),
        70.0 + dailyLoss * daysAgo,
      );
    }
    return manager;
  }

  testWidgets('renders the current weight above the chart', (tester) async {
    final manager = WeightManager(InMemoryWeightRepository());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await manager.addWeight(DateTime(today.year, today.month, today.day - 3), 80.0);
    await manager.addWeight(today, 72.5);

    await pumpPage(tester, manager);

    // The hero figure, plus today's row in the history list below it.
    expect(find.text('72.5 kg'), findsNWidgets(2));
    expect(find.text('as of ${fullDateWithWeekday(today)}'), findsOneWidget);
  });

  testWidgets('renders the three change tiles while losing weight', (
    tester,
  ) async {
    final manager = await rampedManager(0.1);

    await pumpPage(tester, manager);

    expect(find.text('Weekly change'), findsOneWidget);
    expect(find.text('30-day trend'), findsOneWidget);
    expect(find.text('Vs. low'), findsOneWidget);

    // A tenth of a kilogram a day: -0.7 a week, and -3.0 projected over a month.
    expect(find.widgetWithText(StatTile, '-0.7 kg'), findsOneWidget);
    expect(find.text('vs. previous week'), findsOneWidget);
    expect(find.widgetWithText(StatTile, '-0.70 kg/wk'), findsOneWidget);
    expect(find.text('≈ -3.0 kg/month'), findsOneWidget);

    expect(find.byIcon(Icons.arrow_downward_rounded), findsNWidgets(2));
  });

  testWidgets('signs and points the tiles upward while gaining', (
    tester,
  ) async {
    final manager = await rampedManager(-0.1);

    await pumpPage(tester, manager);

    expect(find.widgetWithText(StatTile, '+0.7 kg'), findsOneWidget);
    expect(find.widgetWithText(StatTile, '+0.70 kg/wk'), findsOneWidget);
    expect(find.text('≈ +3.0 kg/month'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNWidgets(2));
  });

  testWidgets('celebrates standing on the all-time low', (tester) async {
    final manager = await rampedManager(0.1);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await pumpPage(tester, manager);

    // The ramp bottoms out today, so the distance from the low is zero.
    expect(find.widgetWithText(StatTile, '0.0 kg'), findsOneWidget);
    expect(find.text('low 70.0 on ${shortDate(today)}'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
  });

  testWidgets('shows the distance from an older low as a signed gap', (
    tester,
  ) async {
    final manager = WeightManager(InMemoryWeightRepository());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lowDay = DateTime(today.year, today.month, today.day - 10);
    await manager.addWeight(lowDay, 72.3);
    await manager.addWeight(today, 73.7);

    await pumpPage(tester, manager);

    expect(find.widgetWithText(StatTile, '+1.4 kg'), findsOneWidget);
    expect(find.text('low 72.3 on ${shortDate(lowDay)}'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsNothing);
  });

  testWidgets('falls back to -- for windows under the span gate', (
    tester,
  ) async {
    final manager = WeightManager(InMemoryWeightRepository());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Two weigh-ins a day apart span one day, under the gate's three.
    await manager.addWeight(DateTime(today.year, today.month, today.day - 1), 73.0);
    await manager.addWeight(today, 72.5);

    await pumpPage(tester, manager);

    // The low is a distance rather than a window, so it reads through the gate.
    expect(find.widgetWithText(StatTile, '--'), findsNWidgets(2));
    expect(find.text('72.5 kg'), findsNWidgets(2));
    expect(find.widgetWithText(StatTile, '0.0 kg'), findsOneWidget);
  });

  testWidgets('an imperial preference converts every figure on the tab', (
    tester,
  ) async {
    final manager = await rampedManager(0.1);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await pumpPage(tester, manager, system: MeasurementSystem.imperial);

    // The hero figure and today's history row, both 70.0 kg.
    expect(find.text('154.3 lbs'), findsNWidgets(2));
    expect(find.text('70.0 kg'), findsNothing);

    // Each tile converts before rounding, so its digits, sign and arrow agree.
    expect(find.widgetWithText(StatTile, '-1.5 lbs'), findsOneWidget);
    expect(find.widgetWithText(StatTile, '-1.54 lbs/wk'), findsOneWidget);
    expect(find.text('≈ -6.6 lbs/month'), findsOneWidget);
    expect(find.text('low 154.3 on ${shortDate(today)}'), findsOneWidget);
  });

  testWidgets('history list only lists the last 7 days of entries', (
    tester,
  ) async {
    final manager = WeightManager(InMemoryWeightRepository());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recentDay = DateTime(today.year, today.month, today.day - 6);
    final oldDay = DateTime(today.year, today.month, today.day - 7);

    await manager.addWeight(recentDay, 71.0);
    await manager.addWeight(oldDay, 73.0);

    await pumpPage(tester, manager);

    expect(find.text(fullDateWithWeekday(recentDay)), findsOneWidget);
    // Scoped to the row: the current-weight figure above the chart carries the
    // latest weigh-in's value too, whatever the history range holds.
    expect(find.widgetWithText(ListTile, '71.0 kg'), findsOneWidget);
    expect(find.text(fullDateWithWeekday(oldDay)), findsNothing);
    expect(find.text('73.0 kg'), findsNothing);
  });

  testWidgets('picking a wider range reveals older entries', (tester) async {
    final manager = WeightManager(InMemoryWeightRepository());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastMonth = DateTime(today.year, today.month, today.day - 20);

    await manager.addWeight(lastMonth, 73.0);

    await pumpPage(tester, manager);

    expect(find.text('Last 7 days'), findsOneWidget);
    expect(
      find.text('No weight entries in the last 7 days. Tap + to log your weight.'),
      findsOneWidget,
    );

    await tester.tap(find.byType(HistoryRangeSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 30 days').last);
    await tester.pumpAndSettle();

    expect(find.text(fullDateWithWeekday(lastMonth)), findsOneWidget);
    expect(find.widgetWithText(ListTile, '73.0 kg'), findsOneWidget);
    expect(manager.historyRange, const DateRange.lastDays(30));
  });

  testWidgets('shows the empty-state placeholder when a stat is missing', (
    tester,
  ) async {
    final manager = WeightManager(InMemoryWeightRepository());

    await pumpPage(tester, manager);

    // Three tiles plus the current-weight figure, all on the placeholder.
    expect(find.widgetWithText(StatTile, '--'), findsNWidgets(3));
    expect(find.text('--'), findsNWidgets(4));
    expect(find.text('No weigh-ins yet'), findsOneWidget);
  });

  testWidgets('swiping a history row leaves the entry alone', (tester) async {
    final manager = WeightManager(InMemoryWeightRepository());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await manager.addWeight(today, 72.5);

    await pumpPage(tester, manager);

    await tester.drag(
      find.widgetWithText(ListTile, '72.5 kg'),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Dismissible), findsNothing);
    expect(find.text(fullDateWithWeekday(today)), findsOneWidget);
    expect(find.widgetWithText(ListTile, '72.5 kg'), findsOneWidget);
    expect(manager.history, hasLength(1));
  });

  testWidgets('the row dialog is still a way to delete an entry', (
    tester,
  ) async {
    final manager = WeightManager(InMemoryWeightRepository());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await manager.addWeight(today, 72.5);

    await pumpPage(tester, manager);

    await tester.tap(find.text(fullDateWithWeekday(today)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text(fullDateWithWeekday(today)), findsNothing);
    expect(manager.history, isEmpty);
  });
}
