class Snack {
  final String name;

  bool get wasEaten => _eatenTime != null;

  DateTime? get eatenTime => _eatenTime;

  DateTime? _eatenTime;

  Snack({required this.name});

  void eat(DateTime now) {
    _eatenTime = now;
  }

  void unEat() {
    _eatenTime = null;
  }
}
