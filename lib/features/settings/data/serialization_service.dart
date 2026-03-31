import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:food_locker/core/csv_serializer.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/food_day_repository.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_config_repository.dart';
import 'package:food_locker/features/food/data/food_type.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SerializationService {
  static const String _configFileName = 'config.csv';
  static const String _historyFileName = 'history.csv';
  static const String _weightFileName = 'weight.csv';
  @visibleForTesting
  static String generateZipFileName([DateTime? now]) {
    final timestamp = now ?? DateTime.now();
    final formatted = '${timestamp.year}'
        '${timestamp.month.toString().padLeft(2, '0')}'
        '${timestamp.day.toString().padLeft(2, '0')}'
        '${timestamp.hour.toString().padLeft(2, '0')}'
        '${timestamp.minute.toString().padLeft(2, '0')}'
        '${timestamp.second.toString().padLeft(2, '0')}';
    return 'food_locker_$formatted.zip';
  }

  SerializationService();

  Future<void> exportData(BuildContext context) async {
    final configRepo = context.read<FoodConfigRepository>();
    final dayRepo = context.read<FoodDayRepository>();
    final weightRepo = context.read<WeightRepository>();

    final zipData = createExportArchive(
      configRepo.foodConfigs,
      dayRepo.getAllDays(),
      weightRepo.getAllWeights(),
    );

    if (zipData == null) return;

    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/${generateZipFileName()}');
    await zipFile.writeAsBytes(zipData);

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(zipFile.path)], text: 'Food Locker Backup');
  }

  Future<void> importData(BuildContext context) async {
    final configRepo = context.read<FoodConfigRepository>();
    final dayRepo = context.read<FoodDayRepository>();
    final weightRepo = context.read<WeightRepository>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final filePath = result?.files.single.path;

    if (filePath == null) return;

    final file = File(filePath);
    final bytes = await file.readAsBytes();

    await importFromArchive(bytes, configRepo, dayRepo, weightRepo);
  }

  @visibleForTesting
  List<int>? createExportArchive(
      List<FoodConfig> configs, List<FoodDay> days, List<Weight> weights) {
    final configCsv = generateConfigCsv(configs);
    final historyCsv = generateHistoryCsv(days);
    final weightCsv = generateWeightCsv(weights);

    final archive = Archive()
      ..addFile(
        ArchiveFile(_configFileName, configCsv.length, configCsv.codeUnits),
      )
      ..addFile(
        ArchiveFile(_historyFileName, historyCsv.length, historyCsv.codeUnits),
      )
      ..addFile(
        ArchiveFile(_weightFileName, weightCsv.length, weightCsv.codeUnits),
      );

    return ZipEncoder().encode(archive);
  }

  @visibleForTesting
  Future<void> importFromArchive(
    List<int> zipBytes,
    FoodConfigRepository configRepo,
    FoodDayRepository dayRepo,
    WeightRepository weightRepo,
  ) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    // Clear existing data
    configRepo.clear();
    await dayRepo.clear();
    await weightRepo.clear();

    for (final file in archive) {
      if (file.isFile) {
        final content = String.fromCharCodes(file.content as List<int>);
        if (file.name == _configFileName) {
          importConfigFromCsv(content, configRepo);
        } else if (file.name == _historyFileName) {
          importHistoryFromCsv(content, dayRepo);
        } else if (file.name == _weightFileName) {
          importWeightFromCsv(content, weightRepo);
        }
      }
    }
  }

  @visibleForTesting
  String generateConfigCsv(List<FoodConfig> configs) {
    final items = configs
        .map((c) => {'name': c.name, 'type': c.type.name})
        .toList();
    return CsvSerializer.toCSV(items);
  }

  @visibleForTesting
  String generateHistoryCsv(List<FoodDay> days) {
    final items = <Map<String, dynamic>>[];

    for (final day in days) {
      final dateStr = day.date.toIso8601String();
      for (final meal in day.meals) {
        items.add({
          'date': dateStr,
          'type': 'meal',
          'name': meal.name,
          'eatenAt': meal.eatenAt?.toIso8601String(),
          'overate': day.overate,
        });
      }
      for (final snack in day.snacks) {
        items.add({
          'date': dateStr,
          'type': 'snack',
          'name': snack.name,
          'eatenAt': snack.eatenAt?.toIso8601String(),
          'overate': day.overate,
        });
      }
    }
    return CsvSerializer.toCSV(items);
  }

  @visibleForTesting
  String generateWeightCsv(List<Weight> weights) {
    final items = weights
        .map((w) => {
              'date': w.date.toIso8601String(),
              'value': w.value,
              'unit': w.unit.name,
            })
        .toList();
    return CsvSerializer.toCSV(items);
  }

  @visibleForTesting
  void importConfigFromCsv(String csv, FoodConfigRepository repo) {
    final items = CsvSerializer.fromCSV(csv);
    for (final item in items) {
      final name = item['name'] as String?;
      final typeStr = item['type'] as String?;

      if (name != null && typeStr != null) {
        try {
          final type = FoodType.values.byName(typeStr);
          repo.add(FoodConfig(name: name, type: type));
        } catch (e) {
          debugPrint('Error parsing config item: $item, $e');
        }
      }
    }
  }

  @visibleForTesting
  void importHistoryFromCsv(String csv, FoodDayRepository repo) {
    final items = CsvSerializer.fromCSV(csv);
    final Map<String, FoodDay> daysMap = {};

    for (final item in items) {
      final dateStr = item['date'] as String?;
      final type = item['type'] as String?;
      final name = item['name'] as String?;
      final eatenAtStr = item['eatenAt'] as String?;
      final overateStr = item['overate']?.toString();

      if (dateStr == null || name == null) continue;

      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      // Normalize date to day
      final dayDate = DateTime(date.year, date.month, date.day);
      final dateKey = dayDate.toIso8601String();

      if (!daysMap.containsKey(dateKey)) {
        final overate = overateStr == 'true';
        daysMap[dateKey] = FoodDay(
          date: dayDate,
          meals: [],
          snacks: [],
          overate: overate,
        );
      }

      final day = daysMap[dateKey]!;
      DateTime? eatenAt;
      if (eatenAtStr != null && eatenAtStr.isNotEmpty) {
        eatenAt = DateTime.tryParse(eatenAtStr);
      }

      final food = Food(name: name, eatenTime: eatenAt);
      if (type == 'meal') {
        day.meals.add(food);
      } else if (type == 'snack') {
        day.snacks.add(food);
      }
    }

    for (final day in daysMap.values) {
      repo.saveDay(day);
    }
  }

  @visibleForTesting
  void importWeightFromCsv(String csv, WeightRepository repo) {
    final items = CsvSerializer.fromCSV(csv);
    for (final item in items) {
      final dateStr = item['date'] as String?;
      final valueStr = item['value']?.toString();
      final unitStr = item['unit'] as String?;

      if (dateStr == null || valueStr == null) continue;

      final date = DateTime.tryParse(dateStr);
      final value = double.tryParse(valueStr);

      if (date != null && value != null) {
        WeightUnit unit = WeightUnit.kilograms;
        if (unitStr != null) {
          try {
            unit = WeightUnit.values.byName(unitStr);
          } catch (e) {
            debugPrint('Error parsing weight unit: $unitStr, $e');
          }
        }
        repo.saveWeight(Weight(date: date, value: value, unit: unit));
      }
    }
  }
}
