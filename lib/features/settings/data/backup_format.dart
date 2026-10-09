import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:food_locker/features/settings/data/text_backup_codec.dart';

/// The container a backup's per-dataset entries are packed into. Both carry
/// the same entries; they differ only in how they travel.
enum BackupFormat {
  zip('zip', 'application/zip'),

  /// What a browser can hand to the Web Share API, which refuses zips.
  text('txt', 'text/plain');

  const BackupFormat(this.extension, this.mimeType);

  final String extension;
  final String mimeType;

  /// What an export writes by default: a zip natively, where the system
  /// share sheet takes any file, and text on web.
  static BackupFormat get platformDefault => kIsWeb ? text : zip;

  /// Every extension import accepts.
  static List<String> get extensions => [for (final f in values) f.extension];

  /// The format whose extension [fileName] carries, or `null` for any other.
  static BackupFormat? fromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    for (final format in values) {
      if (lower.endsWith('.${format.extension}')) return format;
    }
    return null;
  }

  List<int> encode(Archive archive) => switch (this) {
    BackupFormat.zip => ZipEncoder().encode(archive),
    BackupFormat.text => const TextBackupCodec().encode(archive),
  };

  /// Unpacks either format, told apart by content rather than by file name so
  /// a renamed backup still restores.
  ///
  /// Throws a [FormatException] for anything else. The zip decoder reads
  /// arbitrary bytes as an empty archive, which a restore would take as a
  /// backup with no weights and clear them.
  static Archive decode(List<int> bytes) {
    if (TextBackupCodec.looksLikeTextBackup(bytes)) {
      return const TextBackupCodec().decode(bytes);
    }
    if (_isZip(bytes)) return ZipDecoder().decodeBytes(bytes);
    throw const FormatException('Not a Food Locker backup');
  }

  /// A local file header, or the end record an archive with no entries opens
  /// with.
  static bool _isZip(List<int> bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x50 &&
      bytes[1] == 0x4B &&
      ((bytes[2] == 0x03 && bytes[3] == 0x04) ||
          (bytes[2] == 0x05 && bytes[3] == 0x06));
}
