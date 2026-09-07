import 'package:archive/archive.dart';
import 'package:food_locker/core/csv_serializer.dart';
import 'package:food_locker/features/weight/data/weight.dart';

class WeightBackupCodec {
  /// The weight dataset's entry inside a backup zip. Public so the two-store
  /// coordinator (`SerializationService`) can pack it alongside the bite entry
  /// in a single archive.
  static const String weightFileName = 'weight.csv';

  /// The value column, named for its unit so the file says what its numbers
  /// mean.
  static const String valueColumn = 'weight_kg';

  /// The value column older archives used, alongside a `unit` column. Its
  /// values are taken as kilograms whatever that unit said — the app itself
  /// only ever wrote kilograms.
  static const String legacyValueColumn = 'value';

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
              valueColumn: w.value,
            })
        .toList();
    return CsvSerializer.toCSV(items);
  }

  List<Weight> parseWeightCsv(String csv) {
    final List<Weight> weights = [];
    final items = CsvSerializer.fromCSV(csv);
    for (final item in items) {
      final dateStr = item['date'] as String?;
      final valueStr =
          (item[valueColumn] ?? item[legacyValueColumn])?.toString();

      if (dateStr == null || valueStr == null) continue;

      final date = DateTime.tryParse(dateStr);
      final value = double.tryParse(valueStr);

      if (date != null && value != null) {
        weights.add(Weight(date: date, value: value));
      }
    }
    return weights;
  }
}
