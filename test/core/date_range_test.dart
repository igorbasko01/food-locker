import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/date_range.dart';

void main() {
  group('oldestDay', () {
    final now = DateTime(2024, 5, 20, 13, 45);

    test('counts back from the reference day, today included', () {
      expect(const DateRange.lastDays(1).oldestDay(asOf: now), DateTime(2024, 5, 20));
      expect(const DateRange.lastDays(7).oldestDay(asOf: now), DateTime(2024, 5, 14));
      expect(const DateRange.lastDays(30).oldestDay(asOf: now), DateTime(2024, 4, 21));
      expect(const DateRange.lastDays(90).oldestDay(asOf: now), DateTime(2024, 2, 21));
    });

    test('the long spans are day counts, so they drift against the calendar', () {
      // 180 days is a few days short of "6 months back" (Nov 20), and 365 days
      // lands 2 days late across a leap year. The labels are approximate; the
      // spans are exact.
      expect(const DateRange.lastDays(180).oldestDay(asOf: now), DateTime(2023, 11, 23));
      expect(const DateRange.lastDays(365).oldestDay(asOf: now), DateTime(2023, 5, 22));
    });

    test('drops the time of day', () {
      expect(
        const DateRange.lastDays(7).oldestDay(asOf: DateTime(2024, 5, 20, 23, 59, 59)),
        DateTime(2024, 5, 14),
      );
    });

    test('falls back to now when no reference is given', () {
      final today = DateTime.now();

      expect(
        const DateRange.lastDays(7).oldestDay(),
        DateTime(today.year, today.month, today.day - 6),
      );
    });
  });

  group('covers', () {
    final now = DateTime(2024, 5, 20);

    test('takes the oldest day but not the one before it', () {
      const range = DateRange.lastDays(7);

      expect(range.covers(DateTime(2024, 5, 14, 8, 15), asOf: now), isTrue);
      expect(range.covers(DateTime(2024, 5, 13), asOf: now), isFalse);
      expect(range.covers(DateTime(2024, 5, 20), asOf: now), isTrue);
    });

    test('has no upper bound, so a future weigh-in stays visible', () {
      expect(
        const DateRange.lastDays(7).covers(DateTime(2024, 6, 1), asOf: now),
        isTrue,
      );
    });

    test('a day it covered yesterday falls out once the date rolls over', () {
      const range = DateRange.lastDays(7);
      final loadedDay = DateTime(2024, 5, 14);

      expect(range.covers(loadedDay, asOf: now), isTrue);
      expect(range.covers(loadedDay, asOf: DateTime(2024, 5, 21)), isFalse);
    });

    test('measures against today when no reference is given', () {
      final today = DateTime.now();

      expect(
        const DateRange.lastDays(7)
            .covers(DateTime(today.year, today.month, today.day - 6)),
        isTrue,
      );
      expect(
        const DateRange.lastDays(7)
            .covers(DateTime(today.year, today.month, today.day - 7)),
        isFalse,
      );
    });
  });

  test('ranges of the same length are equal', () {
    expect(const DateRange.lastDays(30), const DateRange.lastDays(30));
    expect(
      const DateRange.lastDays(30).hashCode,
      const DateRange.lastDays(30).hashCode,
    );
    expect(const DateRange.lastDays(30), isNot(const DateRange.lastDays(90)));
  });
}
