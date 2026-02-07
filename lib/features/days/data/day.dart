import 'package:food_locker/core/where.dart';
import 'package:food_locker/features/snacks/data/snack.dart';
import 'package:food_locker/features/windows/data/window.dart';

class FoodDay {
  final DateTime date;
  final List<FoodWindow> windows;
  final List<Snack> snacks;

  /// Sort windows by open time
  FoodDay({required this.date, required this.windows, required this.snacks}) {
    windows.sort((a, b) => a.openTime.compareTo(b.openTime));
  }

  /// Returns the window that is currently open
  /// null if no window is open
  FoodWindow? getWindow(DateTime now) {
    return windows.firstWhereOrNull((window) => window.isOpen(now));
  }

  /// Returns the next window that is not closed yet
  /// null if no window is open
  FoodWindow? getNextWindow(DateTime now) {
    return windows.firstWhereOrNull((window) => window.isBefore(now));
  }

  /// Returns the previous window that is closed
  /// null if no windows were closed yet
  FoodWindow? getPreviousWindow(DateTime now) {
    return windows.lastWhereOrNull((window) => window.isAfter(now));
  }
}
