import 'package:flutter/foundation.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';

class WeightManager extends ChangeNotifier {
  final WeightRepository _weightRepository;
  
  List<Weight> _weights = [];

  WeightManager(this._weightRepository);

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
    
    // Update local list
    final existingIndex = _weights.indexWhere((w) {
      return w.date.year == date.year && w.date.month == date.month && w.date.day == date.day;
    });

    if (existingIndex >= 0) {
      _weights[existingIndex] = entry;
    } else {
      _weights.add(entry);
    }
    
    notifyListeners();
  }

  Future<void> deleteWeight(DateTime date) async {
    await _weightRepository.deleteWeight(date);
    _weights.removeWhere((w) {
      return w.date.year == date.year && w.date.month == date.month && w.date.day == date.day;
    });
    notifyListeners();
  }
}
