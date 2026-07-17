import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:food_locker/ui/widgets/daily_bites_chart.dart';

void main() {
  Future<BarChartData> pumpChart(
    WidgetTester tester,
    List<DailyBiteCount> counts, {
    List<Weight> weights = const [],
    DateTime? selectedDay,
    ValueChanged<DateTime>? onDaySelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: DailyBitesChart(
              counts: counts,
              weights: weights,
              selectedDay: selectedDay,
              onDaySelected: onDaySelected,
            ),
          ),
        ),
      ),
    );
    return tester.widget<BarChart>(find.byType(BarChart)).data;
  }

  /// A tap-up touch on the bar at [groupIndex], as fl_chart would deliver it to
  /// `barTouchData.touchCallback`.
  void tapBar(BarChartData data, int groupIndex) {
    final group = data.barGroups[groupIndex];
    final response = BarTouchResponse(
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
    );
    data.barTouchData.touchCallback!(
      FlTapUpEvent(TapUpDetails(kind: PointerDeviceKind.touch)),
      response,
    );
  }

  testWidgets('empty data shows a placeholder, no chart', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DailyBitesChart(counts: [])),
      ),
    );

    expect(find.byType(BarChart), findsNothing);
    expect(find.text('No daily bites to display.'), findsOneWidget);
  });

  testWidgets('sparse data zero-fills gap days into bars', (tester) async {
    // Two logged days with one empty day in between → three bars.
    final data = await pumpChart(tester, [
      DailyBiteCount(day: DateTime(2026, 1, 1), count: 50),
      DailyBiteCount(day: DateTime(2026, 1, 3), count: 20),
    ]);

    expect(data.barGroups, hasLength(3));
    expect(data.barGroups[0].barRods.single.toY, 50);
    expect(data.barGroups[1].barRods.single.toY, 0); // gap day
    expect(data.barGroups[2].barRods.single.toY, 20);
  });

  testWidgets('bars below 40 are muted, bars at or above 40 are full colour', (
    tester,
  ) async {
    final data = await pumpChart(tester, [
      DailyBiteCount(day: DateTime(2026, 1, 1), count: 60), // ≥ 40
      DailyBiteCount(day: DateTime(2026, 1, 2), count: 25), // < 40
    ]);

    final fullColor = appTheme.colorScheme.primary;
    final mutedColor = appTheme.colorScheme.onSurfaceVariant.withValues(
      alpha: 0.4,
    );

    expect(data.barGroups[0].barRods.single.color, fullColor);
    expect(data.barGroups[1].barRods.single.color, mutedColor);
  });

  testWidgets('a reference line marks the average threshold at 40', (
    tester,
  ) async {
    final data = await pumpChart(tester, [
      DailyBiteCount(day: DateTime(2026, 1, 1), count: 60),
    ]);

    final lines = data.extraLinesData.horizontalLines;
    expect(lines, hasLength(1));
    expect(lines.single.y, BiteAnalytics.minBitesForAverage.toDouble());
  });

  testWidgets('exposes a semantics summary for the painted bars', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: DailyBitesChart(
              counts: [
                DailyBiteCount(day: DateTime(2026, 1, 1), count: 60),
                DailyBiteCount(day: DateTime(2026, 1, 3), count: 20),
              ],
            ),
          ),
        ),
      ),
    );

    // Three-day span (a gap day between the two logged days), highest 60.
    expect(
      find.bySemanticsLabel('Daily bites bar chart, 3 days. Highest day 60 bites.'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('the semantics summary announces the selected day', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpChart(
      tester,
      [
        DailyBiteCount(day: DateTime(2026, 1, 1), count: 60),
        DailyBiteCount(day: DateTime(2026, 1, 2), count: 20),
      ],
      selectedDay: DateTime(2026, 1, 2),
    );

    expect(
      find.bySemanticsLabel(
        'Daily bites bar chart, 2 days. Highest day 60 bites. '
        'Selected day ${fullDate(DateTime(2026, 1, 2))}.',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('the semantics summary announces the overlaid weight range', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpChart(
      tester,
      [
        DailyBiteCount(day: DateTime(2026, 1, 1), count: 50),
        DailyBiteCount(day: DateTime(2026, 1, 2), count: 20),
      ],
      weights: [
        Weight(date: DateTime(2026, 1, 1), value: 80),
        Weight(date: DateTime(2026, 1, 2), value: 81),
      ],
    );

    expect(
      find.bySemanticsLabel(
        RegExp(r'Weight overlaid, 80\.0 to 81\.0 kg\.'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('tapping a bar reports its calendar day to onDaySelected', (
    tester,
  ) async {
    DateTime? selected;
    // First day 1/1, a gap day 1/2, then 1/3 → bars at index 0, 1, 2.
    final data = await pumpChart(
      tester,
      [
        DailyBiteCount(day: DateTime(2026, 1, 1), count: 50),
        DailyBiteCount(day: DateTime(2026, 1, 3), count: 20),
      ],
      onDaySelected: (day) => selected = day,
    );

    tapBar(data, 2);
    expect(selected, DateTime(2026, 1, 3));

    tapBar(data, 0);
    expect(selected, DateTime(2026, 1, 1));
  });

  testWidgets('without weights each day has a single bite rod and no right '
      'axis', (tester) async {
    final data = await pumpChart(tester, [
      DailyBiteCount(day: DateTime(2026, 1, 1), count: 50),
      DailyBiteCount(day: DateTime(2026, 1, 2), count: 20),
    ]);

    expect(data.barGroups[0].barRods, hasLength(1));
    expect(data.barGroups[1].barRods, hasLength(1));
    expect(data.titlesData.rightTitles.sideTitles.showTitles, isFalse);
  });

  testWidgets('a day with a weigh-in gets a second weight rod and a right '
      'axis', (tester) async {
    final data = await pumpChart(
      tester,
      [
        DailyBiteCount(day: DateTime(2026, 1, 1), count: 50),
        DailyBiteCount(day: DateTime(2026, 1, 2), count: 20),
      ],
      weights: [
        Weight(date: DateTime(2026, 1, 1), value: 80),
        Weight(date: DateTime(2026, 1, 2), value: 81),
      ],
    );

    // Both days: a bite rod plus a weight rod in the theme's tertiary colour.
    expect(data.barGroups[0].barRods, hasLength(2));
    expect(data.barGroups[1].barRods, hasLength(2));
    expect(data.barGroups[0].barRods[1].color, appTheme.colorScheme.tertiary);
    // The right axis is now labelled (in kg).
    expect(data.titlesData.rightTitles.sideTitles.showTitles, isTrue);
    // A two-item legend accompanies the chart.
    expect(find.text('Bites'), findsOneWidget);
    expect(find.text('Weight (kg)'), findsOneWidget);
  });

  testWidgets('a day weighed but not eaten shows only the weight bar', (
    tester,
  ) async {
    // Bite on 1/1, weigh-in on 1/3 → the range extends to 1/3, whose bite rod
    // is zero-height and whose weight rod carries the weigh-in.
    final data = await pumpChart(
      tester,
      [DailyBiteCount(day: DateTime(2026, 1, 1), count: 50)],
      weights: [Weight(date: DateTime(2026, 1, 3), value: 80)],
    );

    expect(data.barGroups, hasLength(3));
    // 1/1: eaten, not weighed → single bite rod.
    expect(data.barGroups[0].barRods, hasLength(1));
    // 1/3: weighed, not eaten → zero bite rod plus the weight rod.
    expect(data.barGroups[2].barRods, hasLength(2));
    expect(data.barGroups[2].barRods[0].toY, 0);
    expect(data.barGroups[2].barRods[1].toY, greaterThan(0));
  });

  testWidgets('the weight axis fits the weight range so small changes stay '
      'visible', (tester) async {
    // A 1 kg day-to-day change: fitted to [71, 74] it maps to a clearly
    // different bar height, and the lighter day still draws above the floor.
    final data = await pumpChart(
      tester,
      [
        DailyBiteCount(day: DateTime(2026, 1, 1), count: 50),
        DailyBiteCount(day: DateTime(2026, 1, 2), count: 50),
      ],
      weights: [
        Weight(date: DateTime(2026, 1, 1), value: 72),
        Weight(date: DateTime(2026, 1, 2), value: 73),
      ],
    );

    final lighter = data.barGroups[0].barRods[1].toY;
    final heavier = data.barGroups[1].barRods[1].toY;
    // Not flattened from zero: the lighter day is well above the axis floor.
    expect(lighter, greaterThan(0));
    // The 1 kg gain is a visible height difference, not a hairline.
    expect(heavier - lighter, greaterThan(data.maxY * 0.1));
  });

  testWidgets('the selected day\'s bar is highlighted with a border', (
    tester,
  ) async {
    final data = await pumpChart(
      tester,
      [
        DailyBiteCount(day: DateTime(2026, 1, 1), count: 60),
        DailyBiteCount(day: DateTime(2026, 1, 2), count: 20),
      ],
      selectedDay: DateTime(2026, 1, 2),
    );

    // Unselected bar has no border; the selected one does.
    expect(data.barGroups[0].barRods.single.borderSide.width, 0);
    expect(
      data.barGroups[1].barRods.single.borderSide.width,
      greaterThan(0),
    );
    // The selected below-threshold bar reads at full colour, not muted.
    expect(data.barGroups[1].barRods.single.color, appTheme.colorScheme.primary);
  });
}
