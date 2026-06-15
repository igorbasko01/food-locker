import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:hive/hive.dart';

class PersistentWeightRepository implements WeightRepository {
  final Box<Weight> _box;
  final Map<String, double?> _lowestWeightCache = {};

  PersistentWeightRepository(this._box);

  String _getKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  String _getCacheKey(DateTime? since) {
    if (since == null) return 'all_time';
    final normalizedSince = DateTime(since.year, since.month, since.day);
    return 'since_${normalizedSince.toIso8601String()}';
  }

  void _invalidateCache() {
    _lowestWeightCache.clear();
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
    _invalidateCache();
    await _box.put(_getKey(weight.date), weight);
  }

  @override
  Future<void> deleteWeight(DateTime date) async {
    _invalidateCache();
    await _box.delete(_getKey(date));
  }

  @override
  Future<void> clear() async {
    _invalidateCache();
    await _box.clear();
  }

  @override
  double? getLowestWeight({DateTime? since}) {
    final cacheKey = _getCacheKey(since);
    
    if (_lowestWeightCache.containsKey(cacheKey)) {
      return _lowestWeightCache[cacheKey];
    }
    
    if (_box.isEmpty) {
      _lowestWeightCache[cacheKey] = null;
      return null;
    }
    
    var weights = _box.values;
    
    if (since != null) {
      final sinceDateOnly = DateTime(since.year, since.month, since.day);
      weights = weights.where((w) {
        final weightDateOnly = DateTime(w.date.year, w.date.month, w.date.day);
        return weightDateOnly.isAfter(sinceDateOnly) || weightDateOnly.isAtSameMomentAs(sinceDateOnly);
      });
    }
    
    if (weights.isEmpty) {
      _lowestWeightCache[cacheKey] = null;
      return null;
    }
    
    final result = weights.map((w) => w.value).reduce((a, b) => a < b ? a : b);
    _lowestWeightCache[cacheKey] = result;
    return result;
  }

  @override
  DateTime? getOldestWeightDate() {
    if (_box.isEmpty) return null;
    return _box.values
        .map((w) => w.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }
}
