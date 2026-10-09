import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/settings/data/backup_format.dart';
import 'package:food_locker/features/settings/data/text_backup_codec.dart';

ArchiveFile _entry(String name, String content) =>
    ArchiveFile(name, content.length, content.codeUnits);

String _contentOf(Archive archive, String name) => String.fromCharCodes(
  archive.files.firstWhere((f) => f.name == name).content as List<int>,
);

void main() {
  const codec = TextBackupCodec();

  group('TextBackupCodec', () {
    test('writes the header and one section per entry', () {
      final text = utf8.decode(
        codec.encode(
          Archive()
            ..addFile(_entry('weight.csv', 'date,value\r\n2023-10-27,75.5'))
            ..addFile(_entry('bites.csv', 'at_ms\r\n1000')),
        ),
      );

      expect(
        text,
        'food_locker backup v1\n'
        '[weight.csv]\n'
        'date,value\n'
        '2023-10-27,75.5\n'
        '[bites.csv]\n'
        'at_ms\n'
        '1000\n',
      );
    });

    test('round-trips every entry', () {
      final archive = codec.decode(
        codec.encode(
          Archive()
            ..addFile(_entry('weight.csv', 'date,value\r\n2023-10-27,75.5'))
            ..addFile(_entry('profile.csv', 'height_cm\r\n180')),
        ),
      );

      expect(archive.files.map((f) => f.name), ['weight.csv', 'profile.csv']);
      expect(_contentOf(archive, 'weight.csv'), 'date,value\n2023-10-27,75.5');
      expect(_contentOf(archive, 'profile.csv'), 'height_cm\n180');
    });

    test('keeps an empty entry present, distinct from a missing one', () {
      final archive = codec.decode(
        codec.encode(Archive()..addFile(_entry('bites.csv', ''))),
      );

      expect(_contentOf(archive, 'bites.csv'), isEmpty);
      expect(archive.findFile('weight.csv'), isNull);
    });

    test('tolerates CRLF line endings, a BOM and trailing blank lines', () {
      final bytes = utf8.encode(
        '﻿food_locker backup v1\r\n'
        '[weight.csv]\r\n'
        'date,value\r\n'
        '2023-10-27,75.5\r\n'
        '\r\n',
      );

      expect(TextBackupCodec.looksLikeTextBackup(bytes), isTrue);
      expect(
        _contentOf(codec.decode(bytes), 'weight.csv'),
        'date,value\n2023-10-27,75.5',
      );
    });

    test('rejects text without the header', () {
      final bytes = utf8.encode('date,value\n2023-10-27,75.5\n');

      expect(TextBackupCodec.looksLikeTextBackup(bytes), isFalse);
      expect(() => codec.decode(bytes), throwsFormatException);
    });
  });

  group('BackupFormat', () {
    final archive = Archive()..addFile(_entry('weight.csv', 'date,value'));

    test('decodes either format by content, whatever the file is called', () {
      for (final format in BackupFormat.values) {
        final decoded = BackupFormat.decode(format.encode(archive));
        expect(_contentOf(decoded, 'weight.csv'), 'date,value');
      }
    });

    test('rejects bytes that are neither format', () {
      expect(
        () => BackupFormat.decode(utf8.encode('date,value\n')),
        throwsFormatException,
      );
      expect(() => BackupFormat.decode(const []), throwsFormatException);
    });

    test('maps file names to formats', () {
      expect(BackupFormat.fromFileName('a.zip'), BackupFormat.zip);
      expect(BackupFormat.fromFileName('A.TXT'), BackupFormat.text);
      expect(BackupFormat.fromFileName('a.csv'), isNull);
      expect(BackupFormat.extensions, ['zip', 'txt']);
    });

    test('defaults to zip off the web', () {
      expect(BackupFormat.platformDefault, BackupFormat.zip);
    });
  });
}
