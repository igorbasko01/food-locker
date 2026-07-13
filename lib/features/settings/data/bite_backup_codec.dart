import 'package:archive/archive.dart';
import 'package:food_locker/core/csv_serializer.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';

/// CSV backup logic for the bite log (§1c of the pacing plan).
///
/// The two stores each own their own codec; this one turns the bite dataset
/// into a `bites.csv` entry that `SerializationService` packs into the same zip
/// as the weight CSV. Only the raw fact is exported — the epoch-millis
/// timestamp of each bite — following the plan's "store facts, derive views"
/// rule: counts, deltas, and pacing zones are all reconstructable from the
/// timestamps, so exporting them verbatim keeps the backup lossless.
class BiteBackupCodec {
  /// The bite dataset's entry inside a backup zip.
  static const String biteFileName = 'bites.csv';

  const BiteBackupCodec();

  /// The bite CSV packaged as a single [ArchiveFile], so it can be added to a
  /// shared archive that also carries the weight CSV.
  ArchiveFile toArchiveFile(List<Bite> bites) {
    final csvContent = generateBiteCsv(bites);
    return ArchiveFile(biteFileName, csvContent.length, csvContent.codeUnits);
  }

  /// One `at_ms` (epoch millis) per bite, in chronological order. The id is an
  /// insertion-order artifact of the current store, not a fact worth exporting,
  /// so only the timestamp — the atomic fact — is written.
  String generateBiteCsv(List<Bite> bites) {
    final items = bites.map((b) => {'at_ms': b.atMs}).toList();
    return CsvSerializer.toCSV(items);
  }

  /// The bite timestamps carried by a decoded [archive], or null when the
  /// archive has no bite entry at all.
  ///
  /// The null vs. empty distinction is load-bearing on import: a pre-bite
  /// backup (weight-only, no `bites.csv`) simply doesn't describe the bite
  /// log, so its absence must leave existing bites untouched — whereas a
  /// present-but-empty `bites.csv` is a real snapshot of "no bites" and does
  /// clear them.
  List<DateTime>? fromArchive(Archive archive) {
    for (final file in archive) {
      if (file.isFile && file.name == biteFileName) {
        final content = String.fromCharCodes(file.content as List<int>);
        return parseBiteCsv(content);
      }
    }
    return null;
  }

  /// Parses the bite CSV back into instants, one per valid `at_ms` row, in file
  /// order. Rows whose `at_ms` is missing or not an integer are dropped —
  /// the validation half of "validate / dedupe on import". Deduplication of
  /// repeated instants is left to the import coordinator.
  List<DateTime> parseBiteCsv(String csv) {
    final result = <DateTime>[];
    for (final item in CsvSerializer.fromCSV(csv)) {
      final raw = item['at_ms'];
      final ms = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
      if (ms == null) continue;
      result.add(DateTime.fromMillisecondsSinceEpoch(ms));
    }
    return result;
  }
}
