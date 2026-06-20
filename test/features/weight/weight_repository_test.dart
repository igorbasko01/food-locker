import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';
import 'package:food_locker/features/weight/data/weight.dart';

void main() {
  group('WeightRepositoryHelper / InMemoryWeightRepository', () {
    late InMemoryWeightRepository repository;

    setUp(() {
      repository = InMemoryWeightRepository();
    });

    test('getKey returns formatted date string', () {
      final date = DateTime(2023, 5, 20);
      expect(repository.getKey(date), '2023-5-20');
    });

    test('getCacheKey returns correct key based on since date', () {
      expect(repository.getCacheKey(null), 'all_time');
      final since = DateTime(2023, 5, 20);
      expect(
        repository.getCacheKey(since),
        'since_${DateTime(2023, 5, 20).toIso8601String()}',
      );
    });

    test('getLowestWeight returns null when empty', () {
      expect(repository.getLowestWeight(), isNull);
    });

    test('getLowestWeight returns minimum value', () async {
      await repository.saveWeight(Weight(date: DateTime(2023, 5, 10), value: 80.0));
      await repository.saveWeight(Weight(date: DateTime(2023, 5, 11), value: 75.0));
      await repository.saveWeight(Weight(date: DateTime(2023, 5, 12), value: 78.0));

      expect(repository.getLowestWeight(), 75.0);
    });

    test('getLowestWeight with since parameter filters correctly', () async {
      final baseDate = DateTime(2023, 5, 10);
      await repository.saveWeight(Weight(date: baseDate, value: 70.0)); // older, lower
      await repository.saveWeight(Weight(date: baseDate.add(const Duration(days: 2)), value: 75.0));
      await repository.saveWeight(Weight(date: baseDate.add(const Duration(days: 4)), value: 72.0));

      expect(repository.getLowestWeight(since: baseDate.add(const Duration(days: 1))), 72.0);
    });

    test('getLowestWeight caches result and invalidates correctly', () async {
      await repository.saveWeight(Weight(date: DateTime(2023, 5, 10), value: 80.0));
      expect(repository.getLowestWeight(), 80.0);

      // Save a new lower weight, which should invalidate cache
      await repository.saveWeight(Weight(date: DateTime(2023, 5, 11), value: 75.0));
      expect(repository.getLowestWeight(), 75.0);

      // Delete weight, which should invalidate cache
      await repository.deleteWeight(DateTime(2023, 5, 11));
      expect(repository.getLowestWeight(), 80.0);

      // Clear, which should invalidate cache
      await repository.clear();
      expect(repository.getLowestWeight(), isNull);
    });

    test('getOldestWeightDate returns oldest date', () async {
      expect(repository.getOldestWeightDate(), isNull);

      final date1 = DateTime(2023, 5, 12);
      final date2 = DateTime(2023, 5, 10);
      final date3 = DateTime(2023, 5, 15);

      await repository.saveWeight(Weight(date: date1, value: 80.0));
      await repository.saveWeight(Weight(date: date2, value: 75.0));
      await repository.saveWeight(Weight(date: date3, value: 78.0));

      expect(repository.getOldestWeightDate(), date2);
    });
  });
}
