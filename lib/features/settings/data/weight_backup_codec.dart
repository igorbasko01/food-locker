import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:food_locker/core/csv_serializer.dart';
import 'package:food_locker/features/weight/data/weight.dart';

class WeightBackupCodec {
  /// The weight dataset's entry inside a backup zip. Public so the two-store
  /// coordinator (`SerializationService`) can pack it alongside the bite entry
  /// in a single archive.
  static const String weightFileName = 'weight.csv';

  const WeightBackupCodec();

  List<int> encode(List<Weight> weights) {
    return ZipEncoder().encode(Archive()..addFile(toArchiveFile(weights)));
  }

  List<Weight> decode(List<int> zipBytes) {
    return fromArchive(ZipDecoder().decodeBytes(zipBytes));
  }

  /// The weight CSV packaged as a single [ArchiveFile], so it can be added to a
  /// shared archive that also carries the other datasets' CSVs.
  ArchiveFile toArchiveFile(List<Weight> weights) {
    final csvContent = generateWeightCsv(weights);
    return ArchiveFile(weightFileName, csvContent.length, csvContent.codeUnits);
  }

  /// Reads the weights out of a decoded [archive], ignoring any other datasets
  /// packed alongside them (e.g. the bite CSV).
  List<Weight> fromArchive(Archive archive) {
    final List<Weight> weights = [];
    for (final file in archive) {
      if (file.isFile && file.name == weightFileName) {
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
