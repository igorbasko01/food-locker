import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:hive_ce/hive.dart';

class PersistentWeightRepository with WeightRepositoryHelper implements WeightRepository {
  final Box<WeightEntry> _box;

  PersistentWeightRepository(this._box);

  @override
  WeightEntry? getWeightForDay(DateTime date) {
    return _box.get(getKey(date));
  }

  @override
  List<WeightEntry> getAllWeights() {
    return _box.values.toList();
  }

  @override
  Future<void> saveWeight(WeightEntry weight) async {
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

  @override
  bool get isEmpty => _box.isEmpty;
}
