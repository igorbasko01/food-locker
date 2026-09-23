import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/ui/widgets/weekly_change_color.dart';

void main() {
  // Sunday the 9th of August, with the Sunday before it as the predecessor.
  final weekStart = DateTime(2026, 8, 9);
  final previousStart = DateTime(2026, 8, 2);

  /// A week that moved [delta] against the one before it, or a blank week when
  /// [delta] is null.
  WeeklyWeightChange week(double? delta) {
    if (delta == null) return WeeklyWeightChange(weekStart: weekStart);
    return WeeklyWeightChange(
      weekStart: weekStart,
      entries: [Weight(date: weekStart, value: 80.0 + delta)],
      previousEntries: [Weight(date: previousStart, value: 80.0)],
    );
  }

  group('grid scale', () {
    test('a grid with nothing to measure sits at the floor', () {
      expect(
        WeeklyChangeScale.forWeeks([week(null)]).reference,
        WeeklyChangeScale.floor,
      );
      expect(
        WeeklyChangeScale.forWeeks(const []).reference,
        WeeklyChangeScale.floor,
      );
    });

    test('a flat year is not amplified past the floor', () {
      final scale = WeeklyChangeScale.forWeeks([
        for (var i = 0; i < 10; i++) week(0.05),
      ]);

      expect(scale.reference, WeeklyChangeScale.floor);
    });

    test('takes the 90th percentile by nearest rank', () {
      final scale = WeeklyChangeScale.forWeeks([
        for (var magnitude = 1; magnitude <= 10; magnitude++)
          week(magnitude.toDouble()),
      ]);

      expect(scale.reference, closeTo(9.0, 1e-9));
    });

    test('one outlier week does not set the scale for the rest', () {
      final scale = WeeklyChangeScale.forWeeks([
        for (var magnitude = 1; magnitude <= 10; magnitude++)
          week(magnitude.toDouble()),
        week(100.0),
      ]);

      expect(scale.reference, closeTo(10.0, 1e-9));
    });

    test('a loss counts towards the scale by its magnitude', () {
      final losses = WeeklyChangeScale.forWeeks([week(-2.0), week(-2.0)]);
      final gains = WeeklyChangeScale.forWeeks([week(2.0), week(2.0)]);

      expect(losses.reference, gains.reference);
    });

    test('weeks with no delta are left out of the percentile', () {
      final withBlanks = WeeklyChangeScale.forWeeks([
        for (var magnitude = 1; magnitude <= 10; magnitude++)
          week(magnitude.toDouble()),
        for (var i = 0; i < 40; i++) week(null),
      ]);

      expect(withBlanks.reference, closeTo(9.0, 1e-9));
    });
  });

  group('levels', () {
    // A round reference, so the quarter-points land on whole numbers.
    final scale = WeeklyChangeScale.forWeeks([week(4.0)]);

    test('buckets run at a quarter, a half and three quarters of the scale', () {
      expect(scale.levelFor(week(0.99)), 1);
      expect(scale.levelFor(week(1.0)), 2);
      expect(scale.levelFor(week(1.99)), 2);
      expect(scale.levelFor(week(2.0)), 3);
      expect(scale.levelFor(week(2.99)), 3);
      expect(scale.levelFor(week(3.0)), 4);
      expect(scale.levelFor(week(40.0)), 4);
    });

    test('a loss buckets on its magnitude, not its sign', () {
      expect(scale.levelFor(week(-3.0)), 4);
      expect(scale.levelFor(week(-1.2)), 2);
    });

    test('an exact zero is the faintest level, never a gain', () {
      expect(scale.levelFor(week(0.0)), 1);
      expect(week(0.0).isGain, isFalse);
    });

    test('a week with no delta has no level', () {
      expect(scale.levelFor(week(null)), isNull);
    });

    test('the same delta reads stronger on a quieter grid', () {
      final quiet = WeeklyChangeScale.forWeeks([
        for (var i = 0; i < 10; i++) week(1.0),
      ]);
      final dramatic = WeeklyChangeScale.forWeeks([
        for (var i = 0; i < 10; i++) week(8.0),
      ]);

      expect(quiet.levelFor(week(0.9)), 4);
      expect(dramatic.levelFor(week(0.9)), 1);
    });
  });

  group('colour', () {
    final scale = WeeklyChangeScale.forWeeks([week(4.0)]);

    test('a week with no delta is drawn as no data', () {
      expect(weeklyChangeColor(week(null), scale), weeklyChangeNoDataColor);
    });

    test('a gain and a loss of equal size differ', () {
      expect(
        weeklyChangeColor(week(2.0), scale),
        isNot(weeklyChangeColor(week(-2.0), scale)),
      );
    });

    test('a bigger change is drawn darker', () {
      expect(
        weeklyChangeColor(week(-3.0), scale).computeLuminance(),
        lessThan(weeklyChangeColor(week(-0.5), scale).computeLuminance()),
      );
    });
  });
}
