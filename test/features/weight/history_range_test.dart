import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/history_range.dart';

void main() {
  group('HistoryRange.startingFrom', () {
    test('day-counted ranges are inclusive of today', () {
      final now = DateTime(2024, 5, 20, 13, 45);

      expect(HistoryRange.week.startingFrom(now), DateTime(2024, 5, 14));
      expect(HistoryRange.month.startingFrom(now), DateTime(2024, 4, 21));
      expect(HistoryRange.quarter.startingFrom(now), DateTime(2024, 2, 21));
    });

    test('drops the time of day', () {
      expect(
        HistoryRange.week.startingFrom(DateTime(2024, 5, 20, 23, 59, 59)),
        DateTime(2024, 5, 14),
      );
    });

    test('long ranges step by calendar month and year', () {
      final now = DateTime(2024, 5, 20);

      expect(HistoryRange.halfYear.startingFrom(now), DateTime(2023, 11, 20));
      expect(HistoryRange.year.startingFrom(now), DateTime(2023, 5, 20));
    });

    test('half a year back from January lands in the previous year', () {
      expect(
        HistoryRange.halfYear.startingFrom(DateTime(2024, 1, 15)),
        DateTime(2023, 7, 15),
      );
    });

    test('includes the boundary day but not the one before it', () {
      final now = DateTime(2024, 5, 20);

      expect(
        HistoryRange.week.includes(DateTime(2024, 5, 14, 8, 15), now: now),
        isTrue,
      );
      expect(HistoryRange.week.includes(DateTime(2024, 5, 13), now: now), isFalse);
      expect(HistoryRange.week.includes(DateTime(2024, 5, 20), now: now), isTrue);
    });

    test('includes days past today, so a future weigh-in stays visible', () {
      expect(
        HistoryRange.week.includes(
          DateTime(2024, 6, 1),
          now: DateTime(2024, 5, 20),
        ),
        isTrue,
      );
    });

    test('a range loaded yesterday drops the day that fell out overnight', () {
      // The list was loaded on the 20th; by the 21st the 14th is out of range
      // even though it is still in the loaded window.
      final loadedDay = DateTime(2024, 5, 14);

      expect(
        HistoryRange.week.includes(loadedDay, now: DateTime(2024, 5, 20)),
        isTrue,
      );
      expect(
        HistoryRange.week.includes(loadedDay, now: DateTime(2024, 5, 21)),
        isFalse,
      );
    });

    test('every range reaches strictly further back than the shorter ones', () {
      final now = DateTime(2024, 5, 20);
      final starts = HistoryRange.values
          .map((r) => r.startingFrom(now))
          .toList();

      for (var i = 1; i < starts.length; i++) {
        expect(starts[i].isBefore(starts[i - 1]), isTrue,
            reason: '${HistoryRange.values[i]} should start before '
                '${HistoryRange.values[i - 1]}');
      }
    });
  });
}
