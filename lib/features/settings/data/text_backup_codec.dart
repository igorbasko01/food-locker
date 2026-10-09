import 'dart:convert';

import 'package:archive/archive.dart';

/// A plain-text container for the same per-dataset entries a backup zip holds.
///
/// Browsers' Web Share API refuses `.zip` files but accepts `.txt`, so a web
/// export packs its entries into one text file instead:
///
/// ```text
/// food_locker backup v1
/// [weight.csv]
/// date,value
/// 2023-10-27T00:00:00.000,75.5
/// [bites.csv]
/// at_ms
/// ```
///
/// Each `[name]` line opens an entry that runs to the next one. The entries are
/// the datasets' CSVs, whose rows never start with `[`, so no escaping is
/// needed. Decoding yields an [Archive], so the per-store codecs read a text
/// backup exactly as they read a zip.
class TextBackupCodec {
  static const String header = 'food_locker backup v1';

  const TextBackupCodec();

  /// Whether [bytes] open with [header], ignoring a leading byte-order mark
  /// an editor may have added.
  static bool looksLikeTextBackup(List<int> bytes) =>
      _lines(bytes).firstOrNull?.trim() == header;

  List<int> encode(Archive archive) {
    final out = StringBuffer()..writeln(header);
    for (final file in archive) {
      if (!file.isFile) continue;
      out.writeln('[${file.name}]');
      final content = String.fromCharCodes(file.content as List<int>)
          .replaceAll('\r\n', '\n');
      if (content.isEmpty) continue;
      out.write(content);
      if (!content.endsWith('\n')) out.writeln();
    }
    return utf8.encode(out.toString());
  }

  /// Throws a [FormatException] when [bytes] do not start with [header].
  Archive decode(List<int> bytes) {
    final lines = _lines(bytes);
    if (lines.firstOrNull?.trim() != header) {
      throw const FormatException('Not a Food Locker backup');
    }

    final archive = Archive();
    String? name;
    final body = <String>[];

    void flush() {
      final entryName = name;
      if (entryName == null) return;
      while (body.isNotEmpty && body.last.trim().isEmpty) {
        body.removeLast();
      }
      final content = body.join('\n');
      archive.addFile(
        ArchiveFile(entryName, content.length, content.codeUnits),
      );
      body.clear();
    }

    for (final line in lines.skip(1)) {
      final trimmed = line.trim();
      if (trimmed.length > 2 &&
          trimmed.startsWith('[') &&
          trimmed.endsWith(']')) {
        flush();
        name = trimmed.substring(1, trimmed.length - 1);
      } else if (name != null) {
        body.add(line);
      }
    }
    flush();
    return archive;
  }

  static List<String> _lines(List<int> bytes) {
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.startsWith('﻿')) text = text.substring(1);
    return const LineSplitter().convert(text);
  }
}
