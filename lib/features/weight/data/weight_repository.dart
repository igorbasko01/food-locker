import 'package:food_locker/features/weight/data/weight.dart';

abstract class WeightRepository {
  Weight? getWeightForDay(DateTime date);
  Future<void> saveWeight(Weight weight);
  List<Weight> getAllWeights();
  Future<void> deleteWeight(DateTime date);
  Future<void> clear();
  
  /// Returns the lowest weight recorded since [since] (inclusive).
  /// If [since] is null, returns the all-time lowest weight.
  double? getLowestWeight({DateTime? since});

  /// Returns the date of the oldest weight record, or null if empty.
  DateTime? getOldestWeightDate();
}

mixin WeightRepositoryHelper implements WeightRepository {
  final Map<String, double?> _lowestWeightCache = {};

  String getKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  String getCacheKey(DateTime? since) {
    if (since == null) return 'all_time';
    final normalizedSince = DateTime(since.year, since.month, since.day);
    return 'since_${normalizedSince.toIso8601String()}';
  }

  void invalidateCache() {
    _lowestWeightCache.clear();
  }

  @override
  double? getLowestWeight({DateTime? since}) {
    final cacheKey = getCacheKey(since);
    
    if (_lowestWeightCache.containsKey(cacheKey)) {
      return _lowestWeightCache[cacheKey];
    }
    
    final weights = getAllWeights();
    if (weights.isEmpty) {
      _lowestWeightCache[cacheKey] = null;
      return null;
    }
    
    Iterable<Weight> filtered = weights;
    
    if (since != null) {
      final sinceDateOnly = DateTime(since.year, since.month, since.day);
      filtered = filtered.where((w) {
        final weightDateOnly = DateTime(w.date.year, w.date.month, w.date.day);
        return weightDateOnly.isAfter(sinceDateOnly) || weightDateOnly.isAtSameMomentAs(sinceDateOnly);
      });
    }
    
    if (filtered.isEmpty) {
      _lowestWeightCache[cacheKey] = null;
      return null;
    }
    
    final result = filtered.map((w) => w.value).reduce((a, b) => a < b ? a : b);
    _lowestWeightCache[cacheKey] = result;
    return result;
  }

  @override
  DateTime? getOldestWeightDate() {
    final weights = getAllWeights();
    if (weights.isEmpty) return null;
    return weights
        .map((w) => w.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }
}
