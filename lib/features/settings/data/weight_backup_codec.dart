import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:food_locker/core/csv_serializer.dart';
import 'package:food_locker/features/weight/data/weight.dart';

class WeightBackupCodec {
  static const String _weightFileName = 'weight.csv';

  const WeightBackupCodec();

  List<int> encode(List<Weight> weights) {
    final csvContent = generateWeightCsv(weights);

    final archive = Archive()
      ..addFile(
        ArchiveFile(_weightFileName, csvContent.length, csvContent.codeUnits),
      );

    return ZipEncoder().encode(archive) ?? [];
  }

  List<Weight> decode(List<int> zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final List<Weight> weights = [];

    for (final file in archive) {
      if (file.isFile && file.name == _weightFileName) {
        final content = String.fromCharCodes(file.content as List<int>);
        weights.addAll(parseWeightCsv(content));
      }
    }
    return weights;
  }

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

  List<Weight> parseWeightCsv(String csv) {
    final List<Weight> weights = [];
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
        weights.add(Weight(date: date, value: value, unit: unit));
      }
    }
    return weights;
  }
}
