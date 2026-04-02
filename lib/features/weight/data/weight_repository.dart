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
}
