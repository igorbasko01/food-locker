import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/ui/widgets/weekly_change_summary.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Sunday the 8th of March through Saturday the 14th.
  final weekStart = DateTime(2026, 3, 8);

  WeeklyWeightChange week({
    required double delta,
    WeightUnit unit = WeightUnit.kilograms,
  }) => WeeklyWeightChange(
    weekStart: weekStart,
    delta: delta,
    unit: unit,
    firstDate: DateTime(2026, 3, 9),
    firstValue: 82.4,
    lastDate: DateTime(2026, 3, 13),
    lastValue: 82.4 + delta,
  );

  test('a gaining week names its period, its weigh-ins and its change', () {
    expect(weeklyChangeSummary(week(delta: 0.6), 'en_US'), [
      'Sun, 3/8 – Sat, 3/14',
      'Mon, 3/9: 82.4 kg → Fri, 3/13: 83.0 kg',
      '+0.6 kg',
    ]);
  });

  test('a losing week signs its change with a minus', () {
    expect(weeklyChangeSummary(week(delta: -1.2), 'en_US'), [
      'Sun, 3/8 – Sat, 3/14',
      'Mon, 3/9: 82.4 kg → Fri, 3/13: 81.2 kg',
      '-1.2 kg',
    ]);
  });

  test('a flat week states zero rather than a sign', () {
    expect(weeklyChangeSummary(week(delta: 0.0), 'en_US').last, '0.0 kg');
  });

  test('the weigh-ins carry the week\'s own unit', () {
    final summary = weeklyChangeSummary(
      week(delta: 1.4, unit: WeightUnit.pounds),
      'en_US',
    );

    expect(summary[1], 'Mon, 3/9: 82.4 lbs → Fri, 3/13: 83.8 lbs');
    expect(summary.last, '+1.4 lbs');
  });

  test('a week without a delta says so instead of reading as flat', () {
    final summary = weeklyChangeSummary(
      WeeklyWeightChange(weekStart: weekStart),
      'en_US',
    );

    // The same line serves a week nothing was logged in and one whose
    // weigh-ins sat too close together.
    expect(summary, [
      'Sun, 3/8 – Sat, 3/14',
      'No weigh-ins far enough apart to compare',
    ]);
  });

  test('a cell past the end of the grid has no week to name', () {
    expect(weeklyChangeSummary(null, 'en_US'), ['No data']);
  });

  test('renders its dates in the locale field order', () {
    // Day-before-month under en_GB, so the period cannot be the en_US string.
    expect(
      weeklyChangeSummary(week(delta: 0.6), 'en_GB').first,
      isNot(weeklyChangeSummary(week(delta: 0.6), 'en_US').first),
    );
  });
}
