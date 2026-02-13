import 'package:flutter/material.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:food_locker/ui/app_shell.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(FoodAdapter());
  Hive.registerAdapter(FoodDayAdapter());
  await Hive.openBox<FoodDay>('food_days');

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodLocker',
      theme: appTheme,
      home: const AppShell(),
    );
  }
}
