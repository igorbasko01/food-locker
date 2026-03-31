import 'package:food_locker/features/weight/data/weight.dart';

abstract class WeightRepository {
  Weight? getWeightForDay(DateTime date);
  Future<void> saveWeight(Weight weight);
  List<Weight> getAllWeights();
  Future<void> deleteWeight(DateTime date);
  Future<void> clear();
}
