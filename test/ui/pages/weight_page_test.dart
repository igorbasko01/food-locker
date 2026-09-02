import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/core/date_range.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/ui/pages/weight_page.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:food_locker/ui/widgets/history_range_selector.dart';
import 'package:food_locker/ui/widgets/stat_tile.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, WeightManager manager) async {
    // The chart's 1.5 aspect ratio pushes the heading and the history list
    // below the fold on the default 800x600 surface, so they never get built.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: ChangeNotifierProvider<WeightManager>.value(
          value: manager,
          child: const WeightPage(),
        ),
      ),
    );
  }

  testWidgets('renders the three stat tiles with titles, values, and unit', (
    tester,
  ) async {
    final manager = WeightManager(InMemoryWeightRepository());
    final now = DateTime.now();
    // A weight in each window: today (7d/30d/all-time), 10 days ago (30d/all-time),
    // and 100 days ago (all-time only) — so each tile reads a distinct minimum.
    await manager.addWeight(now, 72.5);
    await manager.addWeight(now.subtract(const Duration(days: 10)), 70.0);
    await manager.addWeight(now.subtract(const Duration(days: 100)), 68.0);

    await pumpPage(tester, manager);

    expect(find.text('All Time'), findsOneWidget);
    expect(find.text('30 Days'), findsOneWidget);
    expect(find.text('7 Days'), findsOneWidget);

    expect(find.widgetWithText(StatTile, '68.0'), findsOneWidget);
    expect(find.widgetWithText(StatTile, '70.0'), findsOneWidget);
    expect(find.widgetWithText(StatTile, '72.5'), findsOneWidget);

    // Each populated tile carries the kg unit in its sub-line.
    expect(find.widgetWithText(StatTile, 'kg'), findsNWidgets(3));
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
    expect(find.text('71.0 kg'), findsOneWidget);
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
    expect(find.text('73.0 kg'), findsOneWidget);
    expect(manager.historyRange, const DateRange.lastDays(30));
  });

  testWidgets('shows the empty-state placeholder when a stat is missing', (
    tester,
  ) async {
    final manager = WeightManager(InMemoryWeightRepository());

    await pumpPage(tester, manager);

    // No weights logged: every tile falls back to the -- placeholder with no unit.
    expect(find.widgetWithText(StatTile, '--'), findsNWidgets(3));
    expect(find.widgetWithText(StatTile, 'kg'), findsNothing);
  });
}
