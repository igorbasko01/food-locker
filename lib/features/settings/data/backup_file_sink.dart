import 'package:flutter/foundation.dart';
import 'package:food_locker/features/settings/data/backup_file_sink_io.dart'
    if (dart.library.js_interop) 'package:food_locker/features/settings/data/backup_file_sink_web.dart'
    as platform;

/// Carries backup bytes across the platform boundary — out to wherever the
/// user keeps files, and back in from whatever the file picker chose.
///
/// The rest of the backup path is already byte-based and platform-agnostic, so
/// this is the only seam a web build has to swap out.
abstract class BackupFileSink {
  /// Hands [bytes] to the user as [fileName].
  ///
  /// [onReady] fires once the bytes are committed and before anything the
  /// platform puts up over the app, so callers can clear progress indication
  /// that a share sheet would otherwise cover.
  Future<void> save(String fileName, List<int> bytes, {VoidCallback? onReady});

  /// Reads back a file the picker identified by path rather than by content.
  Future<List<int>> readBytes(String path);
}

/// The sink for the platform this build targets.
BackupFileSink createBackupFileSink() => platform.createBackupFileSink();
