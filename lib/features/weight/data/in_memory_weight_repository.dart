import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';

class InMemoryWeightRepository with WeightRepositoryHelper implements WeightRepository {
  final Map<String, Weight> _weights = {};

  @override
  Weight? getWeightForDay(DateTime date) {
    return _weights[getKey(date)];
  }

  @override
  List<Weight> getAllWeights() {
    return _weights.values.toList();
  }

  @override
  Future<void> saveWeight(Weight weight) async {
    invalidateCache();
    _weights[getKey(weight.date)] = weight;
  }

  @override
  Future<void> deleteWeight(DateTime date) async {
    invalidateCache();
    _weights.remove(getKey(date));
  }

  @override
  Future<void> clear() async {
    invalidateCache();
    _weights.clear();
  }

  @override
  bool get isEmpty => _weights.isEmpty;
}
