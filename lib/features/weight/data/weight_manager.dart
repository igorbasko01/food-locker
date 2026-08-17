import 'package:flutter/foundation.dart';
import 'package:food_locker/features/weight/data/history_range.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_analytics.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';

export 'package:food_locker/features/weight/data/history_range.dart'
    show HistoryRange;
export 'package:food_locker/features/weight/data/weight_analytics.dart'
    show StreakType, OvereatingStats;

class WeightManager extends ChangeNotifier {
  final WeightRepository _weightRepository;
  final WeightAnalytics _analytics;

  // TODO: Add pagination for weight history loading to handle large datasets efficiently.
  List<Weight> _weights = [];
  HistoryRange _historyRange = HistoryRange.week;

  WeightManager(this._weightRepository)
    : _analytics = WeightAnalytics(_weightRepository);

  Future<void> initialize() async {
    _loadHistory();
    notifyListeners();
  }

  /// How far back [history] reaches.
  HistoryRange get historyRange => _historyRange;

  /// The weigh-ins inside [historyRange], newest first.
  ///
  /// The window edge is re-checked here rather than trusted from load time: the
  /// repository query has no upper bound, so [_weights] stays a *superset* of
  /// the range as the clock moves on, and an app left open across midnight
  /// would otherwise keep showing the day that just fell out of range.
  List<Weight> get history {
    final now = DateTime.now();
    final sortedWeights = _weights
        .where((weight) => _historyRange.includes(weight.date, now: now))
        .toList();
    sortedWeights.sort((a, b) => b.date.compareTo(a.date));
    return sortedWeights;
  }

  void selectHistoryRange(HistoryRange range) {
    if (range == _historyRange) return;
    _historyRange = range;
    _loadHistory();
    notifyListeners();
  }

  void _loadHistory() {
    _weights = _weightRepository.getWeightsSince(
      _historyRange.startingFrom(DateTime.now()),
    );
  }

  Future<void> addWeight(
    DateTime date,
    double value, {
    WeightUnit unit = WeightUnit.kilograms,
  }) async {
    final entry = Weight(date: date, value: value, unit: unit);
    await _weightRepository.saveWeight(entry);

    _loadHistory();
    notifyListeners();
  }

  Future<void> updateWeight(
    DateTime oldDate,
    DateTime newDate,
    double newValue, {
    WeightUnit unit = WeightUnit.kilograms,
  }) async {
    final oldDateOnly = DateTime(oldDate.year, oldDate.month, oldDate.day);
    final newDateOnly = DateTime(newDate.year, newDate.month, newDate.day);

    if (oldDateOnly != newDateOnly) {
      await _weightRepository.deleteWeight(oldDate);
    }

    final entry = Weight(date: newDate, value: newValue, unit: unit);
    await _weightRepository.saveWeight(entry);

    _loadHistory();
    notifyListeners();
  }

  Future<void> deleteWeight(DateTime date) async {
    await _weightRepository.deleteWeight(date);

    _loadHistory();
    notifyListeners();
  }

  Weight? getWeightForDate(DateTime date) =>
      _weightRepository.getWeightForDay(date);

  double? get lowestAllTime => _analytics.lowestAllTime;
  double? get lowestLast30Days => _analytics.lowestLast30Days;
  double? get lowestLast7Days => _analytics.lowestLast7Days;

  OvereatingStats get overeatingStats => _analytics.calculateOvereatingStats();
}
