import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/history_range.dart';

void main() {
  group('HistoryRange.oldestDay', () {
    test('day-counted ranges are inclusive of today', () {
      final now = DateTime(2024, 5, 20, 13, 45);

      expect(HistoryRange.week.oldestDay(asOf: now), DateTime(2024, 5, 14));
      expect(HistoryRange.month.oldestDay(asOf: now), DateTime(2024, 4, 21));
      expect(HistoryRange.quarter.oldestDay(asOf: now), DateTime(2024, 2, 21));
    });

    test('drops the time of day', () {
      expect(
        HistoryRange.week.oldestDay(asOf: DateTime(2024, 5, 20, 23, 59, 59)),
        DateTime(2024, 5, 14),
      );
    });

    test('long ranges step by calendar month and year', () {
      final now = DateTime(2024, 5, 20);

      expect(HistoryRange.halfYear.oldestDay(asOf: now), DateTime(2023, 11, 20));
      expect(HistoryRange.year.oldestDay(asOf: now), DateTime(2023, 5, 20));
    });

    test('half a year back from January lands in the previous year', () {
      expect(
        HistoryRange.halfYear.oldestDay(asOf: DateTime(2024, 1, 15)),
        DateTime(2023, 7, 15),
      );
    });

    test('every range reaches strictly further back than the shorter ones', () {
      final now = DateTime(2024, 5, 20);
      final days = HistoryRange.values
          .map((r) => r.oldestDay(asOf: now))
          .toList();

      for (var i = 1; i < days.length; i++) {
        expect(days[i].isBefore(days[i - 1]), isTrue,
            reason: '${HistoryRange.values[i]} should reach further back than '
                '${HistoryRange.values[i - 1]}');
      }
    });
  });

  group('HistoryRange.covers', () {
    test('covers the boundary day but not the one before it', () {
      final now = DateTime(2024, 5, 20);

      expect(
        HistoryRange.week.covers(DateTime(2024, 5, 14, 8, 15), asOf: now),
        isTrue,
      );
      expect(HistoryRange.week.covers(DateTime(2024, 5, 13), asOf: now), isFalse);
      expect(HistoryRange.week.covers(DateTime(2024, 5, 20), asOf: now), isTrue);
    });

    test('covers days past today, so a future weigh-in stays visible', () {
      expect(
        HistoryRange.week.covers(
          DateTime(2024, 6, 1),
          asOf: DateTime(2024, 5, 20),
        ),
        isTrue,
      );
    });

    test('a day loaded yesterday falls out once the date rolls over', () {
      final loadedDay = DateTime(2024, 5, 14);

      expect(
        HistoryRange.week.covers(loadedDay, asOf: DateTime(2024, 5, 20)),
        isTrue,
      );
      expect(
        HistoryRange.week.covers(loadedDay, asOf: DateTime(2024, 5, 21)),
        isFalse,
      );
    });
  });
}
