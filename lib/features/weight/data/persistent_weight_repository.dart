import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:hive_ce/hive.dart';

class PersistentWeightRepository with WeightRepositoryHelper implements WeightRepository {
  final Box<Weight> _box;

  PersistentWeightRepository(this._box);

  @override
  Weight? getWeightForDay(DateTime date) {
    return _box.get(getKey(date));
  }

  @override
  List<Weight> getAllWeights() {
    return _box.values.toList();
  }

  @override
  Future<void> saveWeight(Weight weight) async {
    invalidateCache();
    await _box.put(getKey(weight.date), weight);
  }

  @override
  Future<void> deleteWeight(DateTime date) async {
    invalidateCache();
    await _box.delete(getKey(date));
  }

  @override
  Future<void> clear() async {
    invalidateCache();
    await _box.clear();
  }
}
