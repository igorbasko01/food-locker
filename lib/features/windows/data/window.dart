class FoodWindow {
  final DateTime openTime;
  final Duration duration;
  DateTime get closeTime => openTime.add(duration);

  DateTime? _manuallyClosedTime;

  FoodWindow({required this.openTime, required this.duration});

  bool isOpen(DateTime now) {
    return now.isAfter(openTime) &&
        now.isBefore(closeTime) &&
        _manuallyClosedTime == null;
  }

  bool isClosed(DateTime now) {
    return !isOpen(now);
  }

  bool isBefore(DateTime now) {
    return now.isBefore(openTime);
  }

  bool isAfter(DateTime now) {
    return now.isAfter(closeTime);
  }

  void close() {
    _manuallyClosedTime = DateTime.now();
  }
}
