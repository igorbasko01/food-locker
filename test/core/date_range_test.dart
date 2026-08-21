import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/date_range.dart';

DateTime day(DateTime from, int offset) =>
    DateTime(from.year, from.month, from.day + offset);

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

    test('moves with the clock, so a day drops out when the date rolls', () {
      const range = DateRange.lastDays(7);

      expect(range.oldestDay(asOf: DateTime(2024, 5, 20)), DateTime(2024, 5, 14));
      expect(range.oldestDay(asOf: DateTime(2024, 5, 21)), DateTime(2024, 5, 15));
    });
  });

  group('contains', () {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    test('takes the oldest day but not the one before it', () {
      const range = DateRange.lastDays(7);

      expect(range.contains(day(today, -6)), isTrue);
      expect(range.contains(day(today, -7)), isFalse);
    });

    test('takes today whatever the time of day', () {
      expect(
        const DateRange.lastDays(7).contains(DateTime(
          today.year,
          today.month,
          today.day,
          23,
          59,
        )),
        isTrue,
      );
    });

    test('has no upper bound, so a future weigh-in stays visible', () {
      expect(const DateRange.lastDays(7).contains(day(today, 5)), isTrue);
    });

    test('a longer range takes what a shorter one leaves out', () {
      expect(const DateRange.lastDays(7).contains(day(today, -20)), isFalse);
      expect(const DateRange.lastDays(30).contains(day(today, -20)), isTrue);
    });
  });

  group('between', () {
    test('spans both endpoints inclusively', () {
      final range = DateRange.between(DateTime(2024, 5, 1), DateTime(2024, 5, 10));

      expect(range.days, 10);
      expect(range.from, DateTime(2024, 5, 1));
      expect(range.to, DateTime(2024, 5, 10));
    });

    test('a single day is a span of one', () {
      final range = DateRange.between(DateTime(2024, 5, 1), DateTime(2024, 5, 1));

      expect(range.days, 1);
      expect(range.from, DateTime(2024, 5, 1));
    });

    test('drops the time of day on both endpoints', () {
      final range = DateRange.between(
        DateTime(2024, 5, 1, 22, 30),
        DateTime(2024, 5, 10, 6, 15),
      );

      expect(range.days, 10);
      expect(range.to, DateTime(2024, 5, 10));
    });

    test('counts a span that crosses a leap day', () {
      final range = DateRange.between(DateTime(2024, 2, 27), DateTime(2024, 3, 1));

      expect(range.days, 4);
    });

    test('is anchored, so the clock does not move it', () {
      final range = DateRange.between(DateTime(2024, 5, 1), DateTime(2024, 5, 10));

      expect(range.oldestDay(asOf: DateTime(2030, 1, 1)), DateTime(2024, 5, 1));
    });

    test('is closed above', () {
      final range = DateRange.between(DateTime(2024, 5, 1), DateTime(2024, 5, 10));

      expect(range.contains(DateTime(2024, 5, 1)), isTrue);
      expect(range.contains(DateTime(2024, 5, 10, 18, 0)), isTrue);
      expect(range.contains(DateTime(2024, 4, 30)), isFalse);
      expect(range.contains(DateTime(2024, 5, 11)), isFalse);
    });
  });

  group('equality', () {
    test('ranges of the same length are equal', () {
      expect(const DateRange.lastDays(30), const DateRange.lastDays(30));
      expect(
        const DateRange.lastDays(30).hashCode,
        const DateRange.lastDays(30).hashCode,
      );
      expect(const DateRange.lastDays(30), isNot(const DateRange.lastDays(90)));
    });

    test('anchored ranges compare on both the anchor and the span', () {
      final range = DateRange.between(DateTime(2024, 5, 1), DateTime(2024, 5, 10));

      expect(range, DateRange.between(DateTime(2024, 5, 1), DateTime(2024, 5, 10)));
      expect(range.hashCode,
          DateRange.between(DateTime(2024, 5, 1), DateTime(2024, 5, 10)).hashCode);
      expect(range, isNot(DateRange.between(DateTime(2024, 5, 2), DateTime(2024, 5, 11))));
      expect(range, isNot(const DateRange.lastDays(10)));
    });
  });
}
