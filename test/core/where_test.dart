import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/where.dart';

void main() {
  test(
    'lastWhereOrNull returns the last element that satisfies the predicate',
    () {
      final list = [1, 2, 3, 4, 5];
      final result = list.lastWhereOrNull((element) => element % 2 == 0);
      expect(result, 4);
    },
  );

  test(
    'lastWhereOrNull returns null if no element satisfies the predicate',
    () {
      final list = [1, 3, 5, 7, 9];
      final result = list.lastWhereOrNull((element) => element % 2 == 0);
      expect(result, null);
    },
  );

  test('lastWhereOrNull returns null if list is empty', () {
    final list = <int>[];
    final result = list.lastWhereOrNull((element) => element % 2 == 0);
    expect(result, null);
  });

  test(
    'firstWhereOrNull returns the first element that satisfies the predicate',
    () {
      final list = [1, 2, 3, 4, 5];
      final result = list.firstWhereOrNull((element) => element % 2 == 0);
      expect(result, 2);
    },
  );

  test(
    'firstWhereOrNull returns null if no element satisfies the predicate',
    () {
      final list = [1, 3, 5, 7, 9];
      final result = list.firstWhereOrNull((element) => element % 2 == 0);
      expect(result, null);
    },
  );

  test('firstWhereOrNull returns null if list is empty', () {
    final list = <int>[];
    final result = list.firstWhereOrNull((element) => element % 2 == 0);
    expect(result, null);
  });
}
