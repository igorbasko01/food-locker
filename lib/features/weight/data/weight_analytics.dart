import 'package:food_locker/features/weight/data/weight_repository.dart';

class WeightAnalytics {
  final WeightRepository _weightRepository;

  WeightAnalytics(this._weightRepository);

  double? get lowestAllTime => _weightRepository.getLowestWeight();

  double? get lowestLast30Days => _weightRepository.getLowestWeight(
    since: DateTime.now().subtract(const Duration(days: 30)),
  );

  double? get lowestLast7Days => _weightRepository.getLowestWeight(
    since: DateTime.now().subtract(const Duration(days: 7)),
  );
}
