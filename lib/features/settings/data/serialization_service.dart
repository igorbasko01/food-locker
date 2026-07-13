import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/settings/data/bite_backup_codec.dart';
import 'package:food_locker/features/settings/data/weight_backup_codec.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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

  Future<void> exportData(BuildContext context) async {
    final weightRepo = context.read<WeightRepository>();
    final biteRepo = context.read<BiteRepository>();

    final weights = weightRepo.getAllWeights();
    final bites = await _allBites(biteRepo);

    if (weights.isEmpty && bites.isEmpty) return;

    final zipData = encodeBackup(weights, bites);

    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/${generateZipFileName()}');
    await zipFile.writeAsBytes(zipData);

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(zipFile.path)], text: 'Food Locker Backup');
  }

  /// Packs both datasets into a single backup zip. Each store owns its own
  /// codec (§1c two-store tax); the coordination — one archive, one file per
  /// dataset — lives here so a single export call spans both stores.
  @visibleForTesting
  List<int> encodeBackup(List<Weight> weights, List<Bite> bites) {
    final archive = Archive()
      ..addFile(const WeightBackupCodec().toArchiveFile(weights))
      ..addFile(const BiteBackupCodec().toArchiveFile(bites));
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

  Future<void> importData(BuildContext context) async {
    final weightRepo = context.read<WeightRepository>();
    final biteRepo = context.read<BiteRepository>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final filePath = result?.files.single.path;

    if (filePath == null) return;

    final file = File(filePath);
    final bytes = await file.readAsBytes();

    await restoreFromBackup(weightRepo, biteRepo, bytes);
  }

  /// Replaces both stores' contents with a backup zip — the destructive core of
  /// [importData], kept separate from the file-picker and file-I/O plumbing so
  /// the clear-then-restore path stays unit-testable.
  ///
  /// The single decode is the coordination point for the two-store tax (§1c):
  /// weights and bites are restored from the same archive. Weights are always
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
  }
}
