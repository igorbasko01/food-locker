import 'package:food_locker/features/weight/data/weight.dart';

abstract class WeightRepository {
  Weight? getWeightForDay(DateTime date);
  Future<void> saveWeight(Weight weight);
  List<Weight> getAllWeights();

  /// Weigh-ins whose calendar day falls in `[from, to)` — both bounds and each
  /// weigh-in are compared day-granular (normalised to their calendar day).
  /// Empty when the range holds none.
  List<Weight> getWeightsInRange(DateTime from, DateTime to);

  /// Weigh-ins on or after [since]'s calendar day, newest first.
  /// Unbounded at the top, so future-dated weigh-ins are included.
  List<Weight> getWeightsSince(DateTime since);

  Future<void> deleteWeight(DateTime date);
  Future<void> clear();

  /// Whether the store holds no weigh-in. Implementations answer from the
  /// store's own bookkeeping rather than by reading the entries.
  bool get isEmpty;
  
  /// Returns the lowest weight recorded since [since] (inclusive).
  /// If [since] is null, returns the all-time lowest weight.
  double? getLowestWeight({DateTime? since});
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
  List<Weight> getWeightsInRange(DateTime from, DateTime to) {
    final fromDay = DateTime(from.year, from.month, from.day);
    final toDay = DateTime(to.year, to.month, to.day);
    return getAllWeights().where((w) {
      final day = DateTime(w.date.year, w.date.month, w.date.day);
      return !day.isBefore(fromDay) && day.isBefore(toDay);
    }).toList();
  }

  @override
  List<Weight> getWeightsSince(DateTime since) {
    final sinceDay = DateTime(since.year, since.month, since.day);
    final weights = getAllWeights().where((w) {
      final day = DateTime(w.date.year, w.date.month, w.date.day);
      return !day.isBefore(sinceDay);
    }).toList();
    weights.sort((a, b) => b.date.compareTo(a.date));
    return weights;
  }
}
