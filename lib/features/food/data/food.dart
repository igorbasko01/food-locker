import 'package:hive/hive.dart';

part 'food.g.dart';

/// Food is an entity that can be eaten
@HiveType(typeId: 0)
class Food {
  @HiveField(0)
  final String name;

  bool get wasEaten => _eatenTime != null;

  DateTime? get eatenAt => _eatenTime;

  @HiveField(1)
  DateTime? _eatenTime;

  Food({required this.name, DateTime? eatenTime}) : _eatenTime = eatenTime;

  void eat(DateTime now) {
    _eatenTime = now;
  }

  void unEat() {
    _eatenTime = null;
  }
}
