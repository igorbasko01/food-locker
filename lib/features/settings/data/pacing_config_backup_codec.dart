import 'package:archive/archive.dart';
import 'package:food_locker/core/csv_serializer.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';

/// CSV backup logic for the versioned pacing thresholds.
///
/// The `pacing_config` table is a slowly-changing dimension: every historical
/// bite's zone is only reconstructable from the threshold version effective at
/// its timestamp, so leaving it out of the backup would lose that history on a
/// restore. This codec turns the config versions into a `pacing_config.csv`
/// entry that `SerializationService` packs into the same zip as the weight and
/// bite CSVs.
///
/// Only the facts that define a version are exported — `effective_ms`, `b1_s`,
/// `b2_s`. The autoincrement `id` is an insertion-order artifact of the current
/// store, not a fact worth preserving, so it is dropped exactly as the bite
/// codec drops its own id.
class PacingConfigBackupCodec {
  /// The pacing-config dataset's entry inside a backup zip.
  static const String pacingConfigFileName = 'pacing_config.csv';

  const PacingConfigBackupCodec();

  /// The pacing-config CSV packaged as a single [ArchiveFile], so it can be
  /// added to a shared archive that also carries the weight and bite CSVs.
  ArchiveFile toArchiveFile(List<PacingConfig> configs) {
    final csvContent = generatePacingConfigCsv(configs);
    return ArchiveFile(
      pacingConfigFileName,
      csvContent.length,
      csvContent.codeUnits,
    );
  }

  /// One row per config version: its effective instant and the two boundaries,
  /// in the store's chronological order.
  String generatePacingConfigCsv(List<PacingConfig> configs) {
    final items = configs
        .map((c) => {
              'effective_ms': c.effectiveMs,
              'b1_s': c.b1S,
              'b2_s': c.b2S,
            })
        .toList();
    return CsvSerializer.toCSV(items);
  }

  /// The config versions carried by a decoded [archive], or null when the
  /// archive has no pacing-config entry at all.
  ///
  /// The null vs. empty distinction is load-bearing on import (mirroring the
  /// bite codec): a pre-config backup simply doesn't describe the thresholds,
  /// so its absence must leave the existing config history untouched — whereas
  /// a present-but-empty entry is a real snapshot and does replace it.
  List<PacingConfig>? fromArchive(Archive archive) {
    for (final file in archive) {
      if (file.isFile && file.name == pacingConfigFileName) {
        final content = String.fromCharCodes(file.content as List<int>);
        return parsePacingConfigCsv(content);
      }
    }
    return null;
  }

  /// Parses the pacing-config CSV back into versions, one per valid row, in
  /// file order. Rows missing any of the three integer fields are dropped — the
  /// validation half of "validate / dedupe on import". Deduplication of
  /// repeated versions is left to the import coordinator.
  ///
  /// The reconstructed [PacingConfig] carries a placeholder `id` of 0: the id
  /// is store-assigned on insert (`setPacingConfig` ignores it), so it is never
  /// round-tripped through the backup.
  List<PacingConfig> parsePacingConfigCsv(String csv) {
    final result = <PacingConfig>[];
    for (final item in CsvSerializer.fromCSV(csv)) {
      final effectiveMs = _asInt(item['effective_ms']);
      final b1S = _asInt(item['b1_s']);
      final b2S = _asInt(item['b2_s']);
      if (effectiveMs == null || b1S == null || b2S == null) continue;
      result.add(
        PacingConfig(id: 0, effectiveMs: effectiveMs, b1S: b1S, b2S: b2S),
      );
    }
    return result;
  }

  int? _asInt(Object? raw) =>
      raw is int ? raw : int.tryParse(raw?.toString() ?? '');
}
