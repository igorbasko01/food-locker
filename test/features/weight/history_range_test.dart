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
