import 'package:flutter/foundation.dart';
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

  WeightManager(this._weightRepository)
    : _analytics = WeightAnalytics(_weightRepository);

  Future<void> initialize() async {
    _weights = _weightRepository.getAllWeights();
    notifyListeners();
  }

  List<Weight> get history {
    final sortedWeights = List<Weight>.from(_weights);
    sortedWeights.sort((a, b) => b.date.compareTo(a.date));
    return sortedWeights;
  }

  Future<void> addWeight(
    DateTime date,
    double value, {
    WeightUnit unit = WeightUnit.kilograms,
  }) async {
    final entry = Weight(date: date, value: value, unit: unit);
    await _weightRepository.saveWeight(entry);

    // Refresh from repository to ensure consistency
    _weights = _weightRepository.getAllWeights();
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

    // Refresh from repository to ensure consistency
    _weights = _weightRepository.getAllWeights();
    notifyListeners();
  }

  Future<void> deleteWeight(DateTime date) async {
    await _weightRepository.deleteWeight(date);

    // Refresh from repository to ensure consistency
    _weights = _weightRepository.getAllWeights();
    notifyListeners();
  }

  Weight? getWeightForDate(DateTime date) =>
      _weightRepository.getWeightForDay(date);

  double? get lowestAllTime => _analytics.lowestAllTime;
  double? get lowestLast30Days => _analytics.lowestLast30Days;
  double? get lowestLast7Days => _analytics.lowestLast7Days;

  OvereatingStats get overeatingStats => _analytics.calculateOvereatingStats();
}
