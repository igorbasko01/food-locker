import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';

class InMemoryWeightRepository implements WeightRepository {
  final Map<String, Weight> _weights = {};
  final Map<String, double?> _lowestWeightCache = {};

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
    return _weights[_getKey(date)];
  }

  @override
  List<Weight> getAllWeights() {
    return _weights.values.toList();
  }

  @override
  Future<void> saveWeight(Weight weight) async {
    _invalidateCache();
    _weights[_getKey(weight.date)] = weight;
  }

  @override
  Future<void> deleteWeight(DateTime date) async {
    _invalidateCache();
    _weights.remove(_getKey(date));
  }

  @override
  Future<void> clear() async {
    _invalidateCache();
    _weights.clear();
  }

  @override
  double? getLowestWeight({DateTime? since}) {
    final cacheKey = _getCacheKey(since);
    
    if (_lowestWeightCache.containsKey(cacheKey)) {
      return _lowestWeightCache[cacheKey];
    }
    
    if (_weights.isEmpty) {
      _lowestWeightCache[cacheKey] = null;
      return null;
    }
    
    var weights = _weights.values;
    
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
    if (_weights.isEmpty) return null;
    return _weights.values
        .map((w) => w.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }
}
