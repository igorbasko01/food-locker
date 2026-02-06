import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/windows/data/window.dart';

void main() {
  group('FoodWindow', () {
    test('isOpen returns true when current time is within window', () {
      final now = DateTime.now();
      final window = FoodWindow(
        openTime: now.subtract(const Duration(minutes: 30)),
        duration: const Duration(minutes: 60),
      );

      expect(window.isOpen(now), isTrue);
    });

    test('isOpen returns false when current time is before openTime', () {
      final now = DateTime.now();
      final window = FoodWindow(
        openTime: now.add(const Duration(minutes: 10)),
        duration: const Duration(minutes: 60),
      );

      expect(window.isOpen(now), isFalse);
    });

    test('isOpen returns false when current time is after closeTime', () {
      final now = DateTime.now();
      final window = FoodWindow(
        openTime: now.subtract(const Duration(minutes: 90)),
        duration: const Duration(minutes: 60),
      );

      expect(window.isOpen(now), isFalse);
    });

    test('isClosed returns true when current time is not within window', () {
      final now = DateTime.now();
      final window = FoodWindow(
        openTime: now.add(const Duration(minutes: 10)),
        duration: const Duration(minutes: 60),
      );

      expect(window.isClosed(now), isTrue);
    });

    test(
      'isClosed returns true when manually closed although now is in window range',
      () {
        final now = DateTime.now();
        final window = FoodWindow(
          openTime: now.subtract(const Duration(minutes: 30)),
          duration: const Duration(minutes: 60),
        );

        window.close();

        expect(window.isClosed(now), isTrue);
      },
    );
  });
}
