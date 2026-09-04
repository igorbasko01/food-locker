import 'package:flutter/material.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_manager.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/bite/data/drift_bite_repository.dart';
import 'package:food_locker/features/settings/data/preferences_settings_repository.dart';
import 'package:food_locker/features/settings/data/serialization_service.dart';
import 'package:food_locker/features/settings/data/settings_manager.dart';
import 'package:food_locker/features/settings/data/settings_repository.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:food_locker/features/weight/data/persistent_weight_repository.dart';
import 'package:food_locker/hive_registrar.g.dart';
import 'package:food_locker/ui/app_shell.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting();
  await Hive.initFlutter();
  Hive.registerAdapters();
  final weightBox = await Hive.openBox<Weight>('weights');

  final weightRepository = PersistentWeightRepository(weightBox);

  final weightManager = WeightManager(weightRepository);
  await weightManager.initialize();

  final biteRepository = DriftBiteRepository(BiteDatabase());

  final biteManager = BiteManager(biteRepository);
  await biteManager.initialize();

  final settingsRepository =
      PreferencesSettingsRepository(await SharedPreferences.getInstance());
  final settingsManager = SettingsManager(settingsRepository);

  runApp(
    MultiProvider(
      providers: [
        Provider<WeightRepository>.value(value: weightRepository),
        Provider<BiteRepository>.value(value: biteRepository),
        Provider<SettingsRepository>.value(value: settingsRepository),
        Provider<SerializationService>(create: (_) => SerializationService()),
        ChangeNotifierProvider<WeightManager>.value(value: weightManager),
        ChangeNotifierProvider<BiteManager>.value(value: biteManager),
        ChangeNotifierProvider<SettingsManager>.value(value: settingsManager),
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
