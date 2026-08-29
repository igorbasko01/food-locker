import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_analytics.dart';
import 'package:food_locker/ui/widgets/weekly_change_color.dart';
import 'package:food_locker/ui/widgets/weekly_change_heatmap.dart';

void main() {
  WeeklyWeightChange week(int index, {double? delta, WeightUnit? unit}) =>
      WeeklyWeightChange(
        weekStart: DateTime(2026, 8, 9 - 7 * index),
        delta: delta,
        unit: delta == null ? null : unit ?? WeightUnit.kilograms,
      );

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
}
