import 'dart:typed_data';

import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/settings/data/preferences_settings_repository.dart';
import 'package:food_locker/features/weight/data/persistent_weight_repository.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/hive_registrar.g.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

var _boxCount = 0;

/// A fresh, empty in-memory Hive box of weights. It does no file IO, so it is
/// safe inside `testWidgets` without `runAsync`.
///
/// Each call opens a box under a unique name, because opening an already-open
/// name hands back the existing box and its entries.
Future<Box<Weight>> openTestWeightBox() async {
  // The adapter registry is global to the isolate; both adapters register
  // together, so one typeId is enough to guard on.
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapters();
  }
  return Hive.openBox<Weight>(
    'test_weights_${_boxCount++}',
    bytes: Uint8List(0),
  );
}

/// The production weight repository over [openTestWeightBox].
Future<PersistentWeightRepository> openTestWeightRepository() async =>
    PersistentWeightRepository(await openTestWeightBox());

/// The production settings repository over mocked `shared_preferences`,
/// starting from the given values.
Future<PreferencesSettingsRepository> createTestSettingsRepository({
  double? heightCm,
  MeasurementSystem measurementSystem = MeasurementSystem.metric,
}) async {
  SharedPreferences.setMockInitialValues({
    PreferencesSettingsRepository.measurementSystemKey: measurementSystem.name,
    PreferencesSettingsRepository.heightKey: ?heightCm,
  });
  return PreferencesSettingsRepository(await SharedPreferences.getInstance());
}
