import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/core/date_range.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/settings/data/in_memory_settings_repository.dart';
import 'package:food_locker/features/settings/data/settings_manager.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/ui/pages/home_page.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:food_locker/ui/widgets/weekly_change_heatmap.dart';
import 'package:food_locker/ui/widgets/weight_history_tile.dart';
import 'package:provider/provider.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime daysAgo(int days) =>
      DateTime(today.year, today.month, today.day - days);

  Future<void> pumpPage(
    WidgetTester tester,
    WeightManager manager, {
    MeasurementSystem system = MeasurementSystem.metric,
  }) async {
    // The header pushes the history list below the fold on the default
    // 800x600 surface, so its tiles never get built.
    tester.view.physicalSize = const Size(800, 3000);
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
          child: const HomePage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('history rows read in the preferred system', (tester) async {
    final manager = WeightManager(InMemoryWeightRepository());
    await manager.addWeight(daysAgo(1), 71.6677);
    await manager.addWeight(today, 72.5748);

    await pumpPage(tester, manager, system: MeasurementSystem.imperial);

    expect(find.text('160.0 lbs'), findsOneWidget);
    expect(find.text('158.0 lbs'), findsOneWidget);
    // The day-on-day change is converted from kilograms too.
    expect(find.text('+2.0 lbs'), findsOneWidget);
  });

  testWidgets('the heading names the selected range', (tester) async {
    final manager = WeightManager(InMemoryWeightRepository());
    await manager.addWeight(today, 72.0);

    await pumpPage(tester, manager);

    Future<void> expectHeadingFor(DateRange range, String heading) async {
      manager.selectHistoryRange(range);
      await tester.pump();
      expect(find.text(heading), findsOneWidget);
    }

    expect(find.text('Latest 7 Days of Weight'), findsOneWidget);
    await expectHeadingFor(
      const DateRange.lastDays(30),
      'Latest 30 Days of Weight',
    );
    await expectHeadingFor(
      const DateRange.lastDays(90),
      'Latest 90 Days of Weight',
    );
    await expectHeadingFor(
      const DateRange.lastDays(180),
      'Latest 6 Months of Weight',
    );
    await expectHeadingFor(
      const DateRange.lastDays(365),
      'Latest Year of Weight',
    );
  });

  testWidgets('an empty store keeps the onboarding prompt', (tester) async {
    final manager = WeightManager(InMemoryWeightRepository());

    await pumpPage(tester, manager);

    expect(
      find.text(
        'No weight entries yet.\nTap "Log Weight" above to get started!',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an empty range names the range instead of claiming no entries', (
    tester,
  ) async {
    final manager = WeightManager(InMemoryWeightRepository());
    await manager.addWeight(daysAgo(20), 73.0);

    await pumpPage(tester, manager);

    expect(
      find.text(
        'No weight entries in the last 7 days.\n'
        'Tap "Log Weight" above to add one.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'No weight entries yet.\nTap "Log Weight" above to get started!',
      ),
      findsNothing,
    );

    manager.selectHistoryRange(const DateRange.lastDays(30));
    await tester.pump();

    expect(find.text(fullDateWithWeekday(daysAgo(20))), findsOneWidget);
  });

  testWidgets('the history lists every entry in the selected range', (
    tester,
  ) async {
    final manager = WeightManager(InMemoryWeightRepository());
    for (var day = 0; day < 10; day++) {
      await manager.addWeight(daysAgo(day), 70.0 + day);
    }

    await pumpPage(tester, manager);

    expect(find.byType(WeightHistoryTile), findsNWidgets(7));

    manager.selectHistoryRange(const DateRange.lastDays(30));
    await tester.pump();

    expect(find.byType(WeightHistoryTile), findsNWidgets(10));
    expect(find.text(fullDateWithWeekday(daysAgo(9))), findsOneWidget);
  });

  testWidgets('the heatmap sits under the title block once a week has data', (
    tester,
  ) async {
    final manager = WeightManager(InMemoryWeightRepository());
    // Four weeks of daily weigh-ins, so a week and its predecessor are both
    // logged whatever weekday the test runs on.
    for (var day = 0; day < 28; day++) {
      await manager.addWeight(daysAgo(day), 70.0 + day);
    }

    await pumpPage(tester, manager);

    expect(find.byType(WeeklyChangeHeatmap), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(WeeklyChangeHeatmap)).dy,
      greaterThan(tester.getTopLeft(find.text('Weight Locker')).dy),
    );
    expect(
      tester.getTopLeft(find.byType(WeeklyChangeHeatmap)).dy,
      lessThan(tester.getTopLeft(find.text('Latest 7 Days of Weight')).dy),
    );
    expect(find.textContaining('Weigh in regularly'), findsNothing);
  });

  testWidgets('a grid with nothing coloured yet says what fills it', (
    tester,
  ) async {
    final manager = WeightManager(InMemoryWeightRepository());
    await manager.addWeight(today, 72.0);

    await pumpPage(tester, manager);

    expect(find.byType(WeeklyChangeHeatmap), findsOneWidget);
    expect(find.textContaining('Weigh in regularly'), findsOneWidget);
  });
}
