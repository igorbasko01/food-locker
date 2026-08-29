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

    test('getWeightsInRange returns only weigh-ins inside [from, to)', () async {
      final before = DateTime(2023, 5, 9);
      final fromDay = DateTime(2023, 5, 10);
      final inside = DateTime(2023, 5, 12);
      final toDay = DateTime(2023, 5, 15);
      await repository.saveWeight(Weight(date: before, value: 70.0));
      await repository.saveWeight(Weight(date: fromDay, value: 71.0));
      await repository.saveWeight(Weight(date: inside, value: 72.0));
      await repository.saveWeight(Weight(date: toDay, value: 73.0)); // exclusive

      final days = repository
          .getWeightsInRange(fromDay, toDay)
          .map((w) => w.date)
          .toSet();

      // `from` inclusive, `to` exclusive: the 10th and 12th, not the 9th or 15th.
      expect(days, {fromDay, inside});
    });

    test('getWeightsInRange normalises the bounds to their calendar day',
        () async {
      // A weigh-in stored with a time component still counts by its day: with
      // `to` at midnight of the day after, that day is inside the range.
      await repository.saveWeight(
        Weight(date: DateTime(2023, 5, 12, 14, 30), value: 72.0),
      );

      final result = repository.getWeightsInRange(
        DateTime(2023, 5, 12),
        DateTime(2023, 5, 13),
      );

      expect(result, hasLength(1));
      expect(result.single.value, 72.0);
    });

    test('getWeightsInRange is empty when nothing falls in range', () async {
      await repository.saveWeight(Weight(date: DateTime(2023, 5, 1), value: 70.0));

      expect(
        repository.getWeightsInRange(DateTime(2023, 6, 1), DateTime(2023, 6, 30)),
        isEmpty,
      );
    });

    test('getWeightsSince keeps the day itself and everything after it', () async {
      final since = DateTime(2023, 5, 10);
      await repository.saveWeight(Weight(date: DateTime(2023, 5, 9), value: 70.0));
      await repository.saveWeight(Weight(date: since, value: 71.0));
      // Stored with a time component, and dated past `since` — both still count.
      await repository.saveWeight(
        Weight(date: DateTime(2023, 5, 12, 14, 30), value: 72.0),
      );

      final values = repository.getWeightsSince(since).map((w) => w.value).toSet();

      expect(values, {71.0, 72.0});
    });

    test('getWeightsSince returns the weigh-ins newest first', () async {
      await repository.saveWeight(Weight(date: DateTime(2023, 5, 10), value: 71.0));
      await repository.saveWeight(Weight(date: DateTime(2023, 5, 14), value: 74.0));
      await repository.saveWeight(Weight(date: DateTime(2023, 5, 12), value: 72.0));

      final dates = repository
          .getWeightsSince(DateTime(2023, 5, 10))
          .map((w) => w.date)
          .toList();

      expect(dates, [
        DateTime(2023, 5, 14),
        DateTime(2023, 5, 12),
        DateTime(2023, 5, 10),
      ]);
    });

    test('getWeightsSince is empty when every weigh-in predates it', () async {
      await repository.saveWeight(Weight(date: DateTime(2023, 5, 1), value: 70.0));

      expect(repository.getWeightsSince(DateTime(2023, 6, 1)), isEmpty);
    });

    test('isEmpty tracks whether the store holds anything', () async {
      expect(repository.isEmpty, isTrue);

      await repository.saveWeight(Weight(date: DateTime(2023, 5, 1), value: 70.0));
      expect(repository.isEmpty, isFalse);

      await repository.deleteWeight(DateTime(2023, 5, 1));
      expect(repository.isEmpty, isTrue);

      await repository.saveWeight(Weight(date: DateTime(2023, 5, 2), value: 71.0));
      await repository.clear();
      expect(repository.isEmpty, isTrue);
    });
  });
}
