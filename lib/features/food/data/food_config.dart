import 'package:food_locker/features/food/data/food_type.dart';

class FoodConfig {
  final String name;
  final FoodType type;

  FoodConfig({required this.name, required this.type});

  factory FoodConfig.fromJson(Map<String, dynamic> json) {
    return FoodConfig(
      name: json['name'],
      type: FoodType.values.byName(json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'type': type.name};
  }
}
