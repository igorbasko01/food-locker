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

  void close() {
    _manuallyClosedTime = DateTime.now();
  }
}
