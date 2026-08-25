import 'package:flutter/foundation.dart';
import 'package:food_locker/core/date_range.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_analytics.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';

export 'package:food_locker/features/weight/data/weight_analytics.dart'
    show StreakType, OvereatingStats;

class WeightManager extends ChangeNotifier {
  final WeightRepository _weightRepository;
  final WeightAnalytics _analytics;

  // TODO: Add pagination for weight history loading to handle large datasets efficiently.
  List<Weight> _weights = [];
  DateRange _historyRange = const DateRange.lastDays(7);

  WeightManager(this._weightRepository)
    : _analytics = WeightAnalytics(_weightRepository);

  Future<void> initialize() async {
    _reloadHistory();
  }

  /// Re-reads the store, for callers that replaced its contents without going
  /// through this manager — a backup restore. Ordinary mutations reload
  /// themselves.
  Future<void> refresh() async {
    _reloadHistory();
  }

  DateRange get historyRange => _historyRange;

  /// The weigh-ins inside [historyRange], newest first.
  ///
  /// The range is re-checked on read, not trusted from load time: [_weights] is
  /// loaded unbounded at the top, so it stays a superset as the clock moves on,
  /// and an app left open across midnight would keep listing the day that fell
  /// out of range.
  List<Weight> get history => _weights
      .where((weight) => _historyRange.contains(weight.date))
      .toList(growable: false);

  void selectHistoryRange(DateRange range) {
    if (range == _historyRange) return;
    _historyRange = range;
    _reloadHistory();
  }

  /// The one load path: every mutation reloads and notifies through here.
  void _reloadHistory() {
    _weights = _weightRepository.getWeightsSince(_historyRange.from);
    notifyListeners();
  }

  Future<void> addWeight(
    DateTime date,
    double value, {
    WeightUnit unit = WeightUnit.kilograms,
  }) async {
    final entry = Weight(date: date, value: value, unit: unit);
    await _weightRepository.saveWeight(entry);

    _reloadHistory();
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

    _reloadHistory();
  }

  Future<void> deleteWeight(DateTime date) async {
    await _weightRepository.deleteWeight(date);

    _reloadHistory();
  }

  Weight? getWeightForDate(DateTime date) =>
      _weightRepository.getWeightForDay(date);

  double? get lowestAllTime => _analytics.lowestAllTime;
  double? get lowestLast30Days => _analytics.lowestLast30Days;
  double? get lowestLast7Days => _analytics.lowestLast7Days;

  OvereatingStats get overeatingStats => _analytics.calculateOvereatingStats();
}
