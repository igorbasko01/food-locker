import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/food/data/food.dart';

void main() {
  test('Snack wasEaten returns false when not eaten', () {
    final snack = Food(name: 'Snack');
    expect(snack.wasEaten, false);
  });

  test('Snack wasEaten returns true when eaten', () {
    final snack = Food(name: 'Snack');
    snack.eat(DateTime.now());
    expect(snack.wasEaten, true);
  });

  test('Snack wasEaten returns false when unEaten', () {
    final snack = Food(name: 'Snack');
    snack.eat(DateTime.now());
    snack.unEat();
    expect(snack.wasEaten, false);
  });

  test('Snack eatenTime returns the time when eaten', () {
    final now = DateTime.now();
    final snack = Food(name: 'Snack');
    snack.eat(now);
    expect(snack.eatenAt, now);
  });

  test('Snack eatenTime returns null when not eaten', () {
    final snack = Food(name: 'Snack');
    expect(snack.eatenAt, null);
  });

  test('Snack eatenTime returns null when unEaten', () {
    final snack = Food(name: 'Snack');
    snack.eat(DateTime.now());
    snack.unEat();
    expect(snack.eatenAt, null);
  });
}
