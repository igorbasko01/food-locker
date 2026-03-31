import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';

class InMemoryWeightRepository implements WeightRepository {
  final Map<String, Weight> _weights = {};

  String _getKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  @override
  Weight? getWeightForDay(DateTime date) {
    return _weights[_getKey(date)];
  }

  @override
  List<Weight> getAllWeights() {
    return _weights.values.toList();
  }

  @override
  Future<void> saveWeight(Weight weight) async {
    _weights[_getKey(weight.date)] = weight;
  }

  @override
  Future<void> deleteWeight(DateTime date) async {
    _weights.remove(_getKey(date));
  }

  @override
  Future<void> clear() async {
    _weights.clear();
  }
}
