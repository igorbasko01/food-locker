import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/windows/data/window.dart';

void main() {
  test('FoodDay getWindow returns the window that is currently open', () {
    final now = DateTime.now();
    final window = FoodWindow(
      openTime: now.subtract(const Duration(minutes: 30)),
      duration: const Duration(minutes: 60),
    );
    final day = FoodDay(date: now, windows: [window], snacks: []);
    expect(day.getWindow(now), window);
  });

  test('FoodDay getWindow returns null if no windows provided', () {
    final now = DateTime.now();
    final day = FoodDay(date: now, windows: [], snacks: []);
    expect(day.getWindow(now), null);
  });

  test('FoodDay getWindow returns null if between windows', () {
    final now = DateTime.now();
    final window1 = FoodWindow(
      openTime: now.subtract(const Duration(minutes: 61)),
      duration: const Duration(minutes: 60),
    );
    final window2 = FoodWindow(
      openTime: now.add(const Duration(minutes: 60)),
      duration: const Duration(minutes: 60),
    );
    final day = FoodDay(date: now, windows: [window1, window2], snacks: []);
    expect(day.getWindow(now), null);
  });

  test('FoodDay getWindow returns the correct window in multiple windows', () {
    final now = DateTime.now();
    final window1 = FoodWindow(
      openTime: now.subtract(const Duration(minutes: 120)),
      duration: const Duration(minutes: 60),
    );
    final window2 = FoodWindow(
      openTime: now.subtract(const Duration(minutes: 30)),
      duration: const Duration(minutes: 60),
    );
    final day = FoodDay(date: now, windows: [window1, window2], snacks: []);
    expect(day.getWindow(now), window2);
  });

  test('windows are sorted', () {
    final now = DateTime.now();
    final window1 = FoodWindow(
      openTime: now.subtract(const Duration(minutes: 120)),
      duration: const Duration(minutes: 60),
    );
    final window2 = FoodWindow(
      openTime: now.subtract(const Duration(minutes: 30)),
      duration: const Duration(minutes: 60),
    );
    final day = FoodDay(date: now, windows: [window2, window1], snacks: []);
    // Should check order of windows
    expect(day.windows[0], window1);
    expect(day.windows[1], window2);
  });

  test(
    'FoodDay getNextWindow returns null if current window is the last one',
    () {
      final now = DateTime.now();
      final window1 = FoodWindow(
        openTime: now.subtract(const Duration(minutes: 120)),
        duration: const Duration(minutes: 60),
      );
      final window2 = FoodWindow(
        openTime: now.subtract(const Duration(minutes: 30)),
        duration: const Duration(minutes: 60),
      );
      final day = FoodDay(date: now, windows: [window1, window2], snacks: []);
      expect(day.getNextWindow(now), null);
    },
  );

  test('FoodDay getNextWindow returns null if no windows provided', () {
    final now = DateTime.now();
    final day = FoodDay(date: now, windows: [], snacks: []);
    expect(day.getNextWindow(now), null);
  });

  test('FoodDay getNextWindow returns null if all windows are closed', () {
    final now = DateTime.now();
    final window1 = FoodWindow(
      openTime: now.subtract(const Duration(minutes: 120)),
      duration: const Duration(minutes: 60),
    );
    final window2 = FoodWindow(
      openTime: now.subtract(const Duration(minutes: 61)),
      duration: const Duration(minutes: 60),
    );
    final day = FoodDay(date: now, windows: [window1, window2], snacks: []);
    expect(day.getNextWindow(now), null);
  });

  test(
    'FoodDay getNextWindow returns the next window that is not closed yet',
    () {
      final now = DateTime.now();
      final window1 = FoodWindow(
        openTime: now.subtract(const Duration(minutes: 120)),
        duration: const Duration(minutes: 60),
      );
      final window2 = FoodWindow(
        openTime: now.add(const Duration(minutes: 30)),
        duration: const Duration(minutes: 60),
      );
      final day = FoodDay(date: now, windows: [window1, window2], snacks: []);
      expect(day.getNextWindow(now), window2);
    },
  );

  test(
    'FoodDay getPreviousWindow returns the previous window that is closed',
    () {
      final now = DateTime.now();
      final window1 = FoodWindow(
        openTime: now.subtract(const Duration(minutes: 120)),
        duration: const Duration(minutes: 60),
      );
      final window2 = FoodWindow(
        openTime: now.subtract(const Duration(minutes: 30)),
        duration: const Duration(minutes: 60),
      );
      final day = FoodDay(date: now, windows: [window1, window2], snacks: []);
      expect(day.getPreviousWindow(now), window1);
    },
  );

  test('FoodDay getPreviousWindow returns null if no windows provided', () {
    final now = DateTime.now();
    final day = FoodDay(date: now, windows: [], snacks: []);
    expect(day.getPreviousWindow(now), null);
  });

  test(
    'FoodDay getPreviousWindow returns null if no windows are closed yet',
    () {
      final now = DateTime.now();
      final window1 = FoodWindow(
        openTime: now.add(const Duration(minutes: 120)),
        duration: const Duration(minutes: 60),
      );
      final window2 = FoodWindow(
        openTime: now.add(const Duration(minutes: 30)),
        duration: const Duration(minutes: 60),
      );
      final day = FoodDay(date: now, windows: [window1, window2], snacks: []);
      expect(day.getPreviousWindow(now), null);
    },
  );

  test(
    'FoodDay getPreviousWindow returns the previous window that is closed',
    () {
      final now = DateTime.now();
      final window1 = FoodWindow(
        openTime: now.subtract(const Duration(minutes: 120)),
        duration: const Duration(minutes: 60),
      );
      final window2 = FoodWindow(
        openTime: now.subtract(const Duration(minutes: 30)),
        duration: const Duration(minutes: 60),
      );
      final day = FoodDay(date: now, windows: [window1, window2], snacks: []);
      expect(day.getPreviousWindow(now), window1);
    },
  );
}
