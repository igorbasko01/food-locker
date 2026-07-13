import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:food_locker/features/settings/data/weight_backup_codec.dart';
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

    final zipData = const WeightBackupCodec().encode(
      weightRepo.getAllWeights(),
    );

    if (zipData.isEmpty) return;

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

    await restoreFromBackup(weightRepo, bytes);
  }

  /// Replaces every stored weight with the contents of a backup zip.
  ///
  /// This is the destructive core of [importData], kept separate from the
  /// file-picker and file-I/O plumbing so the clear-then-restore path is
  /// unit-testable. It is also the natural coordination point for the upcoming
  /// two-store import (bite data alongside weights).
  Future<void> restoreFromBackup(
    WeightRepository weightRepo,
    List<int> zipBytes,
  ) async {
    final weights = const WeightBackupCodec().decode(zipBytes);
    await weightRepo.clear();
    for (final weight in weights) {
      await weightRepo.saveWeight(weight);
    }
  }
}
