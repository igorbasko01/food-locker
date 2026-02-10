/// Food is an entity that can be eaten
class Food {
  final String name;

  bool get wasEaten => _eatenTime != null;

  DateTime? get eatenAt => _eatenTime;

  DateTime? _eatenTime;

  Food({required this.name});

  void eat(DateTime now) {
    _eatenTime = now;
  }

  void unEat() {
    _eatenTime = null;
  }
}
