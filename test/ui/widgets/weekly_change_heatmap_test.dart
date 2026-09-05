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
      entries: [
        Weight(date: start, value: 80.0, unit: unit ?? WeightUnit.kilograms),
        Weight(
          date: DateTime(start.year, start.month, start.day + 5),
          value: 80.0 + delta,
          unit: unit ?? WeightUnit.kilograms,
        ),
      ],
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

  String readoutFor(WeeklyWeightChange? week) =>
      weeklyChangeSummary(week).join('\n');

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

  group('cell readout', () {
    // A week that gained: Tuesday's weigh-in through Saturday's.
    final gainingWeek = WeeklyWeightChange(
      weekStart: DateTime(2026, 3, 8),
      entries: [
        Weight(date: DateTime(2026, 3, 10), value: 82.4),
        Weight(date: DateTime(2026, 3, 14), value: 83.0),
      ],
    );
    final losingWeek = WeeklyWeightChange(
      weekStart: DateTime(2026, 3, 15),
      entries: [
        Weight(date: DateTime(2026, 3, 15), value: 83.0),
        Weight(date: DateTime(2026, 3, 21), value: 81.8),
      ],
    );

    List<WeeklyWeightChange> yearOpeningWith(List<WeeklyWeightChange> first) =>
        [...first, ...emptyYear().skip(first.length)];

    testWidgets('holding a cell names its week and the weigh-ins behind it', (
      tester,
    ) async {
      await pump(tester, yearOpeningWith([gainingWeek]));

      final gesture = await tester.startGesture(
        tester.getCenter(cells().first),
      );
      await tester.pump();

      expect(find.text(readoutFor(gainingWeek)), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text(readoutFor(gainingWeek)), findsNothing);
    });

    testWidgets('dragging carries the readout to the next cell', (
      tester,
    ) async {
      await pump(tester, yearOpeningWith([gainingWeek, losingWeek]));

      final gesture = await tester.startGesture(
        tester.getCenter(cells().first),
      );
      await tester.pump();
      await gesture.moveTo(tester.getCenter(cells().at(1)));
      await tester.pump();

      expect(find.text(readoutFor(losingWeek)), findsOneWidget);
      expect(find.text(readoutFor(gainingWeek)), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('dragging off the grid ends the readout', (tester) async {
      await pump(tester, yearOpeningWith([gainingWeek]));

      final gesture = await tester.startGesture(
        tester.getCenter(cells().first),
      );
      await tester.pump();
      expect(find.text(readoutFor(gainingWeek)), findsOneWidget);

      await gesture.moveTo(const Offset(400, 560));
      await tester.pump();

      expect(find.text(readoutFor(gainingWeek)), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a week under the gate says so rather than staying blank', (
      tester,
    ) async {
      await pump(tester, emptyYear());

      final gesture = await tester.startGesture(
        tester.getCenter(cells().first),
      );
      await tester.pump();

      expect(
        find.textContaining('${WeeklyWeightChange.minSpanDays} days apart'),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a cell past the end of the list reads as no data', (
      tester,
    ) async {
      await pump(tester, [gainingWeek]);

      final gesture = await tester.startGesture(tester.getCenter(cells().at(1)));
      await tester.pump();

      expect(find.text(readoutFor(null)), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the readout opens clear of the finger holding the cell', (
      tester,
    ) async {
      // A cell in the last row, so there is room above it to open into.
      final weeks = emptyYear();
      weeks[51] = week(0, delta: 0.6);
      await pump(tester, weeks);

      final cell = tester.getRect(cells().at(51));
      final gesture = await tester.startGesture(cell.center);
      await tester.pump();

      expect(
        tester.getRect(find.text(readoutFor(weeks[51]))).bottom,
        lessThan(cell.top),
      );

      await gesture.up();
      await tester.pumpAndSettle();
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
