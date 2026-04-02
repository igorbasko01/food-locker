import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';

void main() {
  group('WeightManager Statistics', () {
    late WeightManager manager;
    late InMemoryWeightRepository repository;

    setUp(() {
      repository = InMemoryWeightRepository();
      manager = WeightManager(repository);
    });

    test('lowestAllTime returns null when empty', () {
      expect(manager.lowestAllTime, isNull);
    });

    test('lowestAllTime returns global minimum', () async {
      await manager.addWeight(DateTime(2023, 1, 1), 80.0);
      await manager.addWeight(DateTime(2023, 2, 1), 75.0);
      await manager.addWeight(DateTime(2023, 3, 1), 77.0);

      expect(manager.lowestAllTime, 75.0);
    });

    test('lowestLast7Days returns minimum from recent week', () async {
      final now = DateTime.now();
      
      // Outside 7 days
      await manager.addWeight(now.subtract(const Duration(days: 10)), 70.0);
      
      // Within 7 days
      await manager.addWeight(now.subtract(const Duration(days: 5)), 75.0);
      await manager.addWeight(now.subtract(const Duration(days: 2)), 72.0);

      expect(manager.lowestLast7Days, 72.0);
    });

    test('lowestLast30Days returns minimum from recent month', () async {
      final now = DateTime.now();
      
      // Outside 30 days
      await manager.addWeight(now.subtract(const Duration(days: 40)), 65.0);
      
      // Within 30 days but outside 7 days
      await manager.addWeight(now.subtract(const Duration(days: 15)), 68.0);
      
      // Within 7 days
      await manager.addWeight(now.subtract(const Duration(days: 5)), 70.0);

      expect(manager.lowestLast30Days, 68.0);
      expect(manager.lowestLast7Days, 70.0);
      expect(manager.lowestAllTime, 65.0);
    });
  });
}
