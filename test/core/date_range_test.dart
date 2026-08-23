import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/date_range.dart';

DateTime day(DateTime from, int offset) =>
    DateTime(from.year, from.month, from.day + offset);

void main() {
  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  group('from', () {
    test('counts back from today, today included', () {
      expect(const DateRange.lastDays(1).from, today);
      expect(const DateRange.lastDays(7).from, day(today, -6));
      expect(const DateRange.lastDays(30).from, day(today, -29));
    });

    test('is the anchor end of an anchored range', () {
      expect(
        DateRange.between(DateTime(2024, 5, 1), DateTime(2024, 5, 10)).from,
        DateTime(2024, 5, 1),
      );
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
      expect(
        DateRange.between(DateTime(2024, 5, 1), DateTime(2024, 5, 1)).days,
        1,
      );
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
      expect(
        DateRange.between(DateTime(2024, 2, 27), DateTime(2024, 3, 1)).days,
        4,
      );
    });

    test('the preset spans reach the days their labels claim', () {
      final end = DateTime(2024, 5, 20);

      expect(DateRange.between(DateTime(2024, 5, 14), end).days, 7);
      expect(DateRange.between(DateTime(2024, 4, 21), end).days, 30);
      expect(DateRange.between(DateTime(2024, 2, 21), end).days, 90);
      // "6 months" reaches Nov 23 rather than Nov 20, and "a year" reaches
      // May 22 rather than May 20 across the leap day.
      expect(DateRange.between(DateTime(2023, 11, 23), end).days, 180);
      expect(DateRange.between(DateTime(2023, 5, 22), end).days, 365);
    });
  });

  group('contains', () {
    test('takes the oldest day but not the one before it', () {
      const range = DateRange.lastDays(7);

      expect(range.contains(day(today, -6)), isTrue);
      expect(range.contains(day(today, -7)), isFalse);
    });

    test('takes today whatever the time of day', () {
      expect(
        const DateRange.lastDays(7)
            .contains(DateTime(today.year, today.month, today.day, 23, 59)),
        isTrue,
      );
    });

    test('a relative range has no upper bound', () {
      expect(const DateRange.lastDays(7).contains(day(today, 5)), isTrue);
    });

    test('a longer range takes what a shorter one leaves out', () {
      expect(const DateRange.lastDays(7).contains(day(today, -20)), isFalse);
      expect(const DateRange.lastDays(30).contains(day(today, -20)), isTrue);
    });

    test('an anchored range is closed at both ends', () {
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
      expect(
        range.hashCode,
        DateRange.between(DateTime(2024, 5, 1), DateTime(2024, 5, 10)).hashCode,
      );
      expect(
        range,
        isNot(DateRange.between(DateTime(2024, 5, 2), DateTime(2024, 5, 11))),
      );
      expect(range, isNot(const DateRange.lastDays(10)));
    });
  });
}
