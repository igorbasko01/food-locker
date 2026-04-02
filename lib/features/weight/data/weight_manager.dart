import 'package:flutter/foundation.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';

class WeightManager extends ChangeNotifier {
  final WeightRepository _weightRepository;
  
  List<Weight> _weights = [];

  WeightManager(this._weightRepository);

  Weight? getWeightForDate(DateTime date) {
    try {
      return _weights.firstWhere((w) {
        return w.date.year == date.year &&
            w.date.month == date.month &&
            w.date.day == date.day;
      });
    } catch (_) {
      return null;
    }
  }

  List<Weight> get history {
    final sortedWeights = List<Weight>.from(_weights);
    sortedWeights.sort((a, b) => b.date.compareTo(a.date));
    return sortedWeights;
  }

  Future<void> initialize() async {
    _weights = _weightRepository.getAllWeights();
    notifyListeners();
  }

  Future<void> addWeight(DateTime date, double value, {WeightUnit unit = WeightUnit.kilograms}) async {
    final entry = Weight(date: date, value: value, unit: unit);
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

  Future<void> updateWeight(DateTime oldDate, DateTime newDate, double newValue, {WeightUnit unit = WeightUnit.kilograms}) async {
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

  double? get lowestAllTime => _weightRepository.getLowestWeight();
  double? get lowestLast30Days => _weightRepository.getLowestWeight(since: DateTime.now().subtract(const Duration(days: 30)));
  double? get lowestLast7Days => _weightRepository.getLowestWeight(since: DateTime.now().subtract(const Duration(days: 7)));
}
