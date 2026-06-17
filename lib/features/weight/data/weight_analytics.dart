import 'package:food_locker/features/weight/data/weight_repository.dart';

enum StreakType { clean, overeating }

/// Reconstructing the date using calendar components is immune to Daylight Saving
/// Time (DST) transitions (where 24-hour duration math like `date.add(Duration(days: 1))`
/// can land on the same calendar day) and automatically handles calendar month/year rollovers.
extension DateTimeCalendar on DateTime {
  DateTime get nextDay => DateTime(year, month, day + 1);
  DateTime get previousDay => DateTime(year, month, day - 1);
}

class OvereatingStats {
  final StreakType? currentStreakType;
  final DateTime? currentStreakStart;
  final DateTime? currentStreakEnd;
  final DateTime? longestStreakStart;
  final DateTime? longestStreakEnd;

  OvereatingStats({
    this.currentStreakType,
    this.currentStreakStart,
    this.currentStreakEnd,
    this.longestStreakStart,
    this.longestStreakEnd,
  });

  int get currentStreakLength {
    if (currentStreakStart == null || currentStreakEnd == null) return 0;
    return currentStreakEnd!.difference(currentStreakStart!).inDays + 1;
  }

  int get longestCleanStreakLength {
    if (longestStreakStart == null || longestStreakEnd == null) return 0;
    return longestStreakEnd!.difference(longestStreakStart!).inDays + 1;
  }
}

class WeightAnalytics {
  final WeightRepository _weightRepository;

  WeightAnalytics(this._weightRepository);

  double? get lowestAllTime => _weightRepository.getLowestWeight();

  double? get lowestLast30Days => _weightRepository.getLowestWeight(
    since: DateTime.now().subtract(const Duration(days: 30)),
  );

  double? get lowestLast7Days => _weightRepository.getLowestWeight(
    since: DateTime.now().subtract(const Duration(days: 7)),
  );

  bool? _isOvereaten(DateTime date) {
    final weightOnDay = _weightRepository.getWeightForDay(date);
    final weightNextDay = _weightRepository.getWeightForDay(date.nextDay);

    if (weightOnDay != null && weightNextDay != null) {
      return weightNextDay.value > weightOnDay.value;
    }
    return null;
  }

  OvereatingStats calculateOvereatingStats() {
    final oldestDate = _weightRepository.getOldestWeightDate();
    if (oldestDate == null) {
      return OvereatingStats();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final (currentType, currentStart, currentEnd) = _calculateCurrentStreak(today);
    final (longestStart, longestEnd) = _calculateLongestCleanStreak(today, oldestDate);

    return OvereatingStats(
      currentStreakType: currentType,
      currentStreakStart: currentStart,
      currentStreakEnd: currentEnd,
      longestStreakStart: longestStart,
      longestStreakEnd: longestEnd,
    );
  }

  /// Calculates the current streak going backwards day-by-day starting from yesterday.
  (StreakType?, DateTime?, DateTime?) _calculateCurrentStreak(DateTime today) {
    StreakType? currentStreakType;
    DateTime? currentStreakStart;
    DateTime? currentStreakEnd;

    DateTime currentDate = today.previousDay;
    while (true) {
      final overeaten = _isOvereaten(currentDate);

      if (overeaten == null) {
        break; // N/A state breaks the continuous streak
      } else if (!overeaten) {
        if (currentStreakType == StreakType.overeating) break;
        currentStreakType = StreakType.clean;
        currentStreakEnd ??= currentDate;
        currentStreakStart = currentDate;
      } else {
        if (currentStreakType == StreakType.clean) break;
        currentStreakType = StreakType.overeating;
        currentStreakEnd ??= currentDate;
        currentStreakStart = currentDate;
      }
      currentDate = currentDate.previousDay;
    }

    return (currentStreakType, currentStreakStart, currentStreakEnd);
  }

  /// Calculates the longest clean streak going forwards from the oldest weight record up to yesterday.
  (DateTime?, DateTime?) _calculateLongestCleanStreak(DateTime today, DateTime oldestDate) {
    DateTime? longestStreakStart;
    DateTime? longestStreakEnd;

    DateTime? currentStreakStartTemp;
    DateTime? currentStreakEndTemp;

    final oldestDateOnly = DateTime(oldestDate.year, oldestDate.month, oldestDate.day);

    if (oldestDateOnly.isBefore(today)) {
      DateTime iterDate = oldestDateOnly;

      while (iterDate.isBefore(today)) {
        final overeaten = _isOvereaten(iterDate);

        if (overeaten == false) {
          currentStreakStartTemp ??= iterDate;
          currentStreakEndTemp = iterDate;

          final tempLen =
              currentStreakEndTemp.difference(currentStreakStartTemp).inDays +
              1;
          final longestLen =
              longestStreakStart == null || longestStreakEnd == null
              ? 0
              : longestStreakEnd.difference(longestStreakStart).inDays + 1;

          if (tempLen > longestLen) {
            longestStreakStart = currentStreakStartTemp;
            longestStreakEnd = currentStreakEndTemp;
          }
        } else {
          currentStreakStartTemp = null;
          currentStreakEndTemp = null;
        }
        iterDate = iterDate.nextDay;
      }
    }

    return (longestStreakStart, longestStreakEnd);
  }
}
