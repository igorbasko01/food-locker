import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/settings/data/bite_backup_codec.dart';
import 'package:food_locker/features/settings/data/pacing_config_backup_codec.dart';
import 'package:food_locker/features/settings/data/weight_backup_codec.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// Asks the user to confirm replacing their data with the backup [fileName].
/// Returning `false` leaves every store untouched.
typedef ConfirmRestore = Future<bool> Function(String fileName);

class SerializationService {
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

  /// Returns whether there was anything to export — `false` means both stores
  /// were empty and no file was produced, which callers must not report as a
  /// completed export.
  ///
  /// [onShareReady] fires once the zip is written and the share sheet is about
  /// to open, so callers can clear any progress indication before the sheet
  /// covers it.
  Future<bool> exportData(BuildContext context, {VoidCallback? onShareReady}) async {
    final weightRepo = context.read<WeightRepository>();
    final biteRepo = context.read<BiteRepository>();

    final weights = weightRepo.getAllWeights();
    final bites = await _allBites(biteRepo);

    if (weights.isEmpty && bites.isEmpty) return false;

    // Pacing config rides along with real data rather than gating the export:
    // the default is always seeded, so it never on its own makes a backup
    // "non-empty".
    final configs = await biteRepo.allPacingConfigs();

    final zipData = encodeBackup(weights, bites, configs);

    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/${generateZipFileName()}');
    await zipFile.writeAsBytes(zipData);

    onShareReady?.call();

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(zipFile.path)], text: 'Food Locker Backup');
    return true;
  }

  /// Packs every dataset into a single backup zip — weights, bites, and the
  /// pacing-config history. Each dataset owns its own codec; the coordination —
  /// one archive, one file per dataset — lives here so a single export call
  /// spans both stores.
  @visibleForTesting
  List<int> encodeBackup(
    List<Weight> weights,
    List<Bite> bites,
    List<PacingConfig> configs,
  ) {
    final archive = Archive()
      ..addFile(const WeightBackupCodec().toArchiveFile(weights))
      ..addFile(const BiteBackupCodec().toArchiveFile(bites))
      ..addFile(const PacingConfigBackupCodec().toArchiveFile(configs));
    return ZipEncoder().encode(archive);
  }

  /// Every logged bite, read through the repository seam. The bite interface
  /// exposes ranges rather than a bulk getter, so a full-history export is a
  /// range from the epoch to a far-future bound (half-open, so the upper bound
  /// stays safely past any real timestamp).
  Future<List<Bite>> _allBites(BiteRepository biteRepo) {
    return biteRepo.bitesInRange(
      DateTime.fromMillisecondsSinceEpoch(0),
      DateTime.utc(9999),
    );
  }

  /// Returns whether a backup was actually restored — `false` means the file
  /// picker was dismissed or [onConfirm] declined, neither of which callers
  /// may report as an import.
  ///
  /// [onConfirm] gates the restore once a file is chosen, so the page can own
  /// the modal; omitting it restores without asking.
  ///
  /// [onRestoreStart] fires once the restore is about to begin, so callers can
  /// show progress without leaving a message on screen while the picker or the
  /// confirmation is still up.
  Future<bool> importData(
    BuildContext context, {
    ConfirmRestore? onConfirm,
    VoidCallback? onRestoreStart,
  }) async {
    final weightRepo = context.read<WeightRepository>();
    final biteRepo = context.read<BiteRepository>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final picked = result?.files.single;
    final filePath = picked?.path;

    if (picked == null || filePath == null) return false;

    // Reading the file writes nothing; the gate below is what guards the stores.
    final bytes = await File(filePath).readAsBytes();

    return confirmAndRestore(
      weightRepo,
      biteRepo,
      bytes,
      fileName: picked.name,
      onConfirm: onConfirm,
      onRestoreStart: onRestoreStart,
    );
  }

  /// Gates the destructive [restoreFromBackup] behind [onConfirm], apart from
  /// the picker and file I/O so the decline path stays unit-testable. Declining
  /// returns `false` without touching a store.
  @visibleForTesting
  Future<bool> confirmAndRestore(
    WeightRepository weightRepo,
    BiteRepository biteRepo,
    List<int> zipBytes, {
    required String fileName,
    ConfirmRestore? onConfirm,
    VoidCallback? onRestoreStart,
  }) async {
    if (onConfirm != null && !await onConfirm(fileName)) return false;

    onRestoreStart?.call();

    await restoreFromBackup(weightRepo, biteRepo, zipBytes);
    return true;
  }

  /// Replaces both stores' contents with a backup zip — the destructive core of
  /// [importData], kept separate from the file-picker and file-I/O plumbing so
  /// the clear-then-restore path stays unit-testable.
  ///
  /// The single decode is where the two stores are coordinated: weights and
  /// bites are restored from the same archive. Weights are always
  /// replaced; bites are replaced only when the archive actually carries a bite
  /// entry, so restoring an older weight-only backup leaves existing bites
  /// alone rather than wiping them.
  Future<void> restoreFromBackup(
    WeightRepository weightRepo,
    BiteRepository biteRepo,
    List<int> zipBytes,
  ) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    final weights = const WeightBackupCodec().fromArchive(archive);
    await weightRepo.clear();
    for (final weight in weights) {
      await weightRepo.saveWeight(weight);
    }

    final bites = const BiteBackupCodec().fromArchive(archive);
    if (bites != null) {
      await biteRepo.clearBites();
      final seen = <int>{};
      for (final at in bites) {
        // Dedupe by instant so a backup with repeated rows — or a re-import of
        // the same file — never double-logs a bite.
        if (seen.add(at.millisecondsSinceEpoch)) {
          await biteRepo.logBite(at);
        }
      }
    }

    final configs = const PacingConfigBackupCodec().fromArchive(archive);
    if (configs != null) {
      // Same null-vs-empty contract as bites: a pre-config (older) backup has
      // no entry and leaves the seeded thresholds alone; a present entry is a
      // full snapshot and replaces the history. Dedupe by effective instant,
      // which keys a version.
      await biteRepo.clearPacingConfigs();
      final seen = <int>{};
      for (final cfg in configs) {
        if (seen.add(cfg.effectiveMs)) {
          await biteRepo.setPacingConfig(cfg);
        }
      }
    }
  }
}
