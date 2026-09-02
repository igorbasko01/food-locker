import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_analytics.dart';
import 'package:food_locker/ui/widgets/weekly_change_color.dart';
import 'package:food_locker/ui/widgets/weekly_change_heatmap.dart';
import 'package:food_locker/ui/widgets/weekly_change_summary.dart';

void main() {
  /// The week [index] grids back from the 9th of August, gaining or losing
  /// [delta] between a Sunday and a Friday weigh-in.
  WeeklyWeightChange week(int index, {double? delta, WeightUnit? unit}) {
    final start = DateTime(2026, 8, 9 - 7 * index);
    if (delta == null) return WeeklyWeightChange(weekStart: start);
    return WeeklyWeightChange(
      weekStart: start,
      delta: delta,
      unit: unit ?? WeightUnit.kilograms,
      firstDate: start,
      firstValue: 80.0,
      lastDate: DateTime(start.year, start.month, start.day + 5),
      lastValue: 80.0 + delta,
    );
  }

  List<WeeklyWeightChange> emptyYear() =>
      [for (var i = 51; i >= 0; i--) week(i)];

  Future<void> pump(WidgetTester tester, List<WeeklyWeightChange> weeks) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeeklyChangeHeatmap(weeks: weeks)),
        ),
      );

  // Nothing inside the heatmap but a cell decorates a box, so these are the
  // cells, in row-major order.
  Finder cells() => find.descendant(
    of: find.byType(WeeklyChangeHeatmap),
    matching: find.byType(DecoratedBox),
  );

  List<Color?> cellColors(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(cells())
      .map((box) => (box.decoration as BoxDecoration).color)
      .toList();

  Finder tooltips() => find.descendant(
    of: find.byType(WeeklyChangeHeatmap),
    matching: find.byType(Tooltip),
  );

  String tooltipAt(WidgetTester tester, int index) =>
      tester.widgetList<Tooltip>(tooltips()).elementAt(index).message!;

  testWidgets('draws 52 cells in 4 rows of 13', (tester) async {
    await pump(tester, emptyYear());

    expect(
      find.descendant(
        of: find.byType(WeeklyChangeHeatmap),
        matching: find.byType(Row),
      ),
      findsNWidgets(WeeklyChangeHeatmap.rows),
    );
    expect(cellColors(tester), hasLength(52));
    // The grid must hold exactly the weeks analytics supplies: the list is
    // oldest-first, so a grid too small would silently drop the newest weeks.
    expect(
      WeeklyChangeHeatmap.rows * WeeklyChangeHeatmap.columns,
      WeightAnalytics.heatmapWeeks,
    );
  });

  testWidgets('a week under the entry threshold is drawn as no data', (
    tester,
  ) async {
    await pump(tester, emptyYear());

    expect(
      cellColors(tester).every((color) => color == weeklyChangeNoDataColor),
      isTrue,
    );
  });

  testWidgets('a gain and a loss of equal size get different colours', (
    tester,
  ) async {
    final weeks = emptyYear();
    weeks[0] = week(51, delta: 1.5);
    weeks[1] = week(50, delta: -1.5);

    await pump(tester, weeks);
    final colors = cellColors(tester);

    expect(colors[0], isNot(colors[1]));
    expect(colors[0], isNot(weeklyChangeNoDataColor));
    expect(colors[1], isNot(weeklyChangeNoDataColor));
  });

  testWidgets('a bigger change is drawn darker', (tester) async {
    final weeks = emptyYear();
    weeks[0] = week(51, delta: -0.1);
    weeks[1] = week(50, delta: -1.5);

    await pump(tester, weeks);
    final colors = cellColors(tester);

    expect(colors[1]!.computeLuminance(), lessThan(colors[0]!.computeLuminance()));
  });

  testWidgets('the current week takes the last cell', (tester) async {
    final weeks = emptyYear();
    weeks[51] = week(0, delta: 2.0);

    await pump(tester, weeks);
    final colors = cellColors(tester);

    expect(colors.last, isNot(weeklyChangeNoDataColor));
    expect(
      colors.take(51).every((color) => color == weeklyChangeNoDataColor),
      isTrue,
    );
  });

  testWidgets('a short list leaves the trailing cells as no data', (
    tester,
  ) async {
    await pump(tester, [week(51, delta: -1.0)]);
    final colors = cellColors(tester);

    expect(colors, hasLength(52));
    expect(colors.first, isNot(weeklyChangeNoDataColor));
    expect(
      colors.skip(1).every((color) => color == weeklyChangeNoDataColor),
      isTrue,
    );
  });

  group('cell summaries', () {
    // A week that gained: Tuesday's weigh-in through Saturday's.
    final gainingWeek = WeeklyWeightChange(
      weekStart: DateTime(2026, 3, 8),
      delta: 0.6,
      unit: WeightUnit.kilograms,
      firstDate: DateTime(2026, 3, 10),
      firstValue: 82.4,
      lastDate: DateTime(2026, 3, 14),
      lastValue: 83.0,
    );
    final losingWeek = WeeklyWeightChange(
      weekStart: DateTime(2026, 3, 15),
      delta: -1.2,
      unit: WeightUnit.kilograms,
      firstDate: DateTime(2026, 3, 15),
      firstValue: 83.0,
      lastDate: DateTime(2026, 3, 21),
      lastValue: 81.8,
    );

    List<WeeklyWeightChange> yearOpeningWith(List<WeeklyWeightChange> first) =>
        [...first, ...emptyYear().skip(first.length)];

    testWidgets('every cell carries its week as a tooltip', (tester) async {
      await pump(tester, yearOpeningWith([gainingWeek, losingWeek]));

      expect(tooltips(), findsNWidgets(52));
      expect(tooltipAt(tester, 0), weeklyChangeSummary(gainingWeek).join('\n'));
      expect(tooltipAt(tester, 1), weeklyChangeSummary(losingWeek).join('\n'));
    });

    testWidgets('a week under the gate says so rather than staying blank', (
      tester,
    ) async {
      await pump(tester, emptyYear());

      final summary = tooltipAt(tester, 0);
      expect(summary, weeklyChangeSummary(emptyYear().first).join('\n'));
      expect(summary, contains('No weigh-ins'));
    });

    testWidgets('a cell past the end of the list reads as no data', (
      tester,
    ) async {
      await pump(tester, [gainingWeek]);

      expect(tooltipAt(tester, 1), weeklyChangeSummary(null).join('\n'));
    });

    testWidgets('the tooltip lasts as long as the cell is held', (
      tester,
    ) async {
      await pump(tester, yearOpeningWith([gainingWeek]));
      final summary = tooltipAt(tester, 0);

      final gesture = await tester.startGesture(tester.getCenter(cells().at(0)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(summary), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text(summary), findsNothing);
    });

    testWidgets('a press that turns into a scroll drops the tooltip', (
      tester,
    ) async {
      await pump(tester, yearOpeningWith([gainingWeek]));
      final summary = tooltipAt(tester, 0);

      final gesture = await tester.startGesture(tester.getCenter(cells().at(0)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(summary), findsOneWidget);

      await gesture.moveBy(const Offset(0, -60));
      await tester.pumpAndSettle();

      expect(find.text(summary), findsNothing);

      await gesture.up();
    });

    testWidgets('each cell is readable without holding it', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, yearOpeningWith([gainingWeek]));

      expect(
        find.bySemanticsLabel(weeklyChangeSummary(gainingWeek).join('. ')),
        findsOneWidget,
      );

      handle.dispose();
    });
  });
}
