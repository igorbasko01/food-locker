import 'package:food_locker/features/weight/data/hive_weight_entry.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:hive_ce/hive.dart';

class PersistentWeightRepository with WeightRepositoryHelper implements WeightRepository {
  final Box<HiveWeightEntry> _box;

  PersistentWeightRepository(this._box);

  @override
  WeightEntry? getWeightForDay(DateTime date) {
    return _box.get(getKey(date))?.toEntry();
  }

  @override
  List<WeightEntry> getAllWeights() {
    return _box.values.map((stored) => stored.toEntry()).toList();
  }

  @override
  Future<void> saveWeight(WeightEntry weight) async {
    invalidateCache();
    await _box.put(getKey(weight.date), HiveWeightEntry.fromEntry(weight));
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
