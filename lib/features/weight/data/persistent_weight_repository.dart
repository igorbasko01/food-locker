import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:hive/hive.dart';

class PersistentWeightRepository implements WeightRepository {
  final Box<Weight> _box;

  PersistentWeightRepository(this._box);

  String _getKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  @override
  Weight? getWeightForDay(DateTime date) {
    return _box.get(_getKey(date));
  }

  @override
  List<Weight> getAllWeights() {
    return _box.values.toList();
  }

  @override
  Future<void> saveWeight(Weight weight) async {
    await _box.put(_getKey(weight.date), weight);
  }

  @override
  Future<void> deleteWeight(DateTime date) async {
    await _box.delete(_getKey(date));
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
