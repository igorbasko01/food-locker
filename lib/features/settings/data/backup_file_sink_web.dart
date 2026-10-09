import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:food_locker/features/settings/data/backup_file_sink.dart'
    show BackupFileSink;
import 'package:food_locker/features/settings/data/backup_format.dart';
import 'package:web/web.dart' as web;

BackupFileSink createBackupFileSink() => const WebBackupFileSink();

/// Offers the backup to the system share sheet where the browser allows it,
/// and otherwise delivers it as an ordinary browser download.
///
/// Chrome's Web Share API accepts only an allowlist of file types that
/// includes `.txt` but not `.zip`, which is why web exports are text.
class WebBackupFileSink implements BackupFileSink {
  const WebBackupFileSink();

  @override
  Future<void> save(
    String fileName,
    List<int> bytes, {
    VoidCallback? onReady,
  }) async {
    final type =
        BackupFormat.fromFileName(fileName)?.mimeType ??
        'application/octet-stream';
    final parts = <JSAny>[Uint8List.fromList(bytes).toJS].toJS;

    onReady?.call();

    final file = web.File(parts, fileName, web.FilePropertyBag(type: type));
    if (await _share(file)) return;
    _download(fileName, web.Blob(parts, web.BlobPropertyBag(type: type)));
  }

  /// Whether the share sheet took the file. A dismissed sheet counts as
  /// handled; anything else — no API, a refused type, an expired user
  /// gesture — leaves the download to deliver it.
  Future<bool> _share(web.File file) async {
    try {
      final data = web.ShareData(files: [file].toJS);
      if (!web.window.navigator.canShare(data)) return false;
      await web.window.navigator.share(data).toDart;
      return true;
    } catch (e) {
      // A rejection surfaces as the JS error itself, which a Dart type test
      // cannot match, so the DOMException is recognised by its name.
      return e.toString().contains('AbortError');
    }
  }

  void _download(String fileName, web.Blob blob) {
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = fileName;
    // Safari only downloads from an anchor that is in the document.
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    // Firefox and Safari fetch the blob after the current task ends, so
    // revoking it here would cancel the download in the very browsers the
    // appended anchor above is for.
    Future.delayed(
      const Duration(minutes: 1),
      () => web.URL.revokeObjectURL(url),
    );
  }

  @override
  Future<List<int>> readBytes(String path) => throw UnsupportedError(
    'The browser file picker returns bytes, never a readable path.',
  );
}
