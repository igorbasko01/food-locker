import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:food_locker/features/settings/data/backup_file_sink.dart'
    show BackupFileSink;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

BackupFileSink createBackupFileSink() => const IoBackupFileSink();

/// Stages the backup in the temporary directory and hands that file to the
/// system share sheet, which is how the user gets it somewhere durable on a
/// platform where the app cannot write to their own storage directly.
class IoBackupFileSink implements BackupFileSink {
  const IoBackupFileSink();

  @override
  Future<void> save(
    String fileName,
    List<int> bytes, {
    VoidCallback? onReady,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/$fileName');
    await zipFile.writeAsBytes(bytes);

    onReady?.call();

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(zipFile.path)], text: 'Food Locker Backup');
  }

  @override
  Future<List<int>> readBytes(String path) => File(path).readAsBytes();
}
