import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:food_locker/features/settings/data/backup_file_sink.dart'
    show BackupFileSink;
import 'package:web/web.dart' as web;

BackupFileSink createBackupFileSink() => const WebBackupFileSink();

/// Delivers the backup as an ordinary browser download.
///
/// The Web Share API is not a usable substitute: it accepts files only on
/// Chrome for Android, so an anchor click is the one route every browser takes.
class WebBackupFileSink implements BackupFileSink {
  const WebBackupFileSink();

  @override
  Future<void> save(
    String fileName,
    List<int> bytes, {
    VoidCallback? onReady,
  }) async {
    final blob = web.Blob(
      <JSAny>[Uint8List.fromList(bytes).toJS].toJS,
      web.BlobPropertyBag(type: 'application/zip'),
    );
    final url = web.URL.createObjectURL(blob);

    onReady?.call();

    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = fileName;
    // Safari only downloads from an anchor that is in the document.
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }

  @override
  Future<List<int>> readBytes(String path) => throw UnsupportedError(
    'The browser file picker returns bytes, never a readable path.',
  );
}
