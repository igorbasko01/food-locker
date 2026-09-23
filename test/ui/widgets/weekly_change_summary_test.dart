import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/ui/widgets/weekly_change_summary.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  // Sunday the 8th of March through Saturday the 14th, after the week the 1st
  // opens.
  final weekStart = DateTime(2026, 3, 8);
  final previousStart = DateTime(2026, 3, 1);

  /// A week of [count] weigh-ins averaging 82.4 kg plus [delta], against a
  /// previous week of [previousCount] averaging 82.4 kg.
  WeeklyWeightChange week({
    required double delta,
    int count = 2,
    int previousCount = 2,
  }) => WeeklyWeightChange(
    weekStart: weekStart,
    entries: [
      for (var day = 0; day < count; day++)
        Weight(
          date: DateTime(weekStart.year, weekStart.month, weekStart.day + day),
          value: 82.4 + delta,
        ),
    ],
    previousEntries: [
      for (var day = 0; day < previousCount; day++)
        Weight(
          date: DateTime(
            previousStart.year,
            previousStart.month,
            previousStart.day + day,
          ),
          value: 82.4,
        ),
    ],
  );

  test('a gaining week names its period, its means and its change', () {
    expect(weeklyChangeSummary(week(delta: 0.6), locale: 'en_US'), [
      'Sun, 3/8 – Sat, 3/14',
      'avg 83.0 kg (2 weigh-ins) vs 82.4 kg the week before (2)',
      '+0.6 kg',
    ]);
  });

  test('a losing week signs its change with a minus', () {
    expect(
      weeklyChangeSummary(week(delta: -1.2), locale: 'en_US').last,
      '-1.2 kg',
    );
  });

  test('a flat week states zero rather than a sign', () {
    expect(
      weeklyChangeSummary(week(delta: 0.0), locale: 'en_US').last,
      '0.0 kg',
    );
  });

  test('a mean resting on one weigh-in reads in the singular', () {
    expect(
      weeklyChangeSummary(
        week(delta: 0.6, count: 1, previousCount: 1),
        locale: 'en_US',
      )[1],
      'avg 83.0 kg (1 weigh-in) vs 82.4 kg the week before (1)',
    );
  });

  test('an imperial preference converts the stored kilograms', () {
    final summary = weeklyChangeSummary(
      week(delta: 0.9071847),
      system: MeasurementSystem.imperial,
      locale: 'en_US',
    );

    expect(
      summary[1],
      'avg 183.7 lbs (2 weigh-ins) vs 181.7 lbs the week before (2)',
    );
    expect(summary.last, '+2.0 lbs');
  });

  test('a week nothing was logged in says so', () {
    expect(
      weeklyChangeSummary(
        WeeklyWeightChange(weekStart: weekStart),
        locale: 'en_US',
      ),
      ['Sun, 3/8 – Sat, 3/14', 'No weigh-ins logged'],
    );
  });

  test('a week whose predecessor is blank says which side is missing', () {
    expect(
      weeklyChangeSummary(
        WeeklyWeightChange(
          weekStart: weekStart,
          entries: [Weight(date: DateTime(2026, 3, 9), value: 82.4)],
        ),
        locale: 'en_US',
      ),
      ['Sun, 3/8 – Sat, 3/14', 'No weigh-ins the week before'],
    );
  });

  test('a cell past the end of the grid has no week to name', () {
    expect(weeklyChangeSummary(null, locale: 'en_US'), ['No data']);
  });

  test('renders its dates in the locale field order', () {
    // Day-before-month under en_GB, so the period cannot be the en_US string.
    expect(
      weeklyChangeSummary(week(delta: 0.6), locale: 'en_GB').first,
      isNot(weeklyChangeSummary(week(delta: 0.6), locale: 'en_US').first),
    );
  });
}
