import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:food_locker/core/csv_serializer.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SerializationService {
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
    final weightRepo = context.read<WeightRepository>();

    final zipData = createExportArchive(
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
    final weightRepo = context.read<WeightRepository>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final filePath = result?.files.single.path;

    if (filePath == null) return;

    final file = File(filePath);
    final bytes = await file.readAsBytes();

    await importFromArchive(bytes, weightRepo);
  }

  @visibleForTesting
  List<int>? createExportArchive(List<Weight> weights) {
    final weightCsv = generateWeightCsv(weights);

    final archive = Archive()
      ..addFile(
        ArchiveFile(_weightFileName, weightCsv.length, weightCsv.codeUnits),
      );

    return ZipEncoder().encode(archive);
  }

  @visibleForTesting
  Future<void> importFromArchive(
    List<int> zipBytes,
    WeightRepository weightRepo,
  ) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    // Clear existing data
    await weightRepo.clear();

    for (final file in archive) {
      if (file.isFile) {
        final content = String.fromCharCodes(file.content as List<int>);
        if (file.name == _weightFileName) {
          importWeightFromCsv(content, weightRepo);
        }
      }
    }
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
