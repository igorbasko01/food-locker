import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:food_locker/ui/widgets/daily_bites_chart.dart';

void main() {
  Future<BarChartData> pumpChart(
    WidgetTester tester,
    List<DailyBiteCount> counts,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: SizedBox(height: 300, child: DailyBitesChart(counts: counts)),
        ),
      ),
    );
    return tester.widget<BarChart>(find.byType(BarChart)).data;
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
}
