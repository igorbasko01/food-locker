import 'package:flutter/material.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:food_locker/features/days/data/persistent_food_day_repository.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:food_locker/features/food/data/food_config_repository.dart';
import 'package:food_locker/features/food/data/persistent_food_config_repository.dart';
import 'package:food_locker/features/days/data/food_day_repository.dart';
import 'package:food_locker/features/settings/data/serialization_service.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:food_locker/features/weight/data/persistent_weight_repository.dart';
import 'package:food_locker/ui/app_shell.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(FoodAdapter());
  Hive.registerAdapter(FoodDayAdapter());
  Hive.registerAdapter(WeightAdapter());
  Hive.registerAdapter(WeightUnitAdapter());
  final foodDayBox = await Hive.openBox<FoodDay>('food_days');
  final weightBox = await Hive.openBox<Weight>('weights');

  final prefs = await SharedPreferences.getInstance();
  final foodConfigRepository = PersistentFoodConfigRepository(prefs);
  final foodDayRepository = PersistentFoodDayRepository(foodDayBox);
  final weightRepository = PersistentWeightRepository(weightBox);

  final foodDayManager = FoodDayManager(
    null,
    foodConfigRepository,
    foodDayRepository,
  );
  await foodDayManager.initialize(DateTime.now());

  final weightManager = WeightManager(weightRepository);
  await weightManager.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<FoodConfigRepository>.value(
          value: foodConfigRepository,
        ),
        Provider<FoodDayRepository>.value(value: foodDayRepository),
        Provider<WeightRepository>.value(value: weightRepository),
        Provider<SerializationService>(create: (_) => SerializationService()),
        ChangeNotifierProvider<FoodDayManager>.value(value: foodDayManager),
        ChangeNotifierProvider<WeightManager>.value(value: weightManager),
      ],
      child: const MainApp(),
    ),
  );
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
