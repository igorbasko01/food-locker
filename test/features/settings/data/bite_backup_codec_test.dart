import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/settings/data/bite_backup_codec.dart';

void main() {
  const codec = BiteBackupCodec();

  group('BiteBackupCodec CSV Logic', () {
    test('generateBiteCsv writes one at_ms per bite under an at_ms header', () {
      final bites = [
        const Bite(id: 1, atMs: 1000),
        const Bite(id: 2, atMs: 31000),
      ];

      final csv = codec.generateBiteCsv(bites);

      expect(csv, contains('at_ms'));
      expect(csv, contains('1000'));
      expect(csv, contains('31000'));
    });

    test('generateBiteCsv of no bites is empty', () {
      expect(codec.generateBiteCsv([]), isEmpty);
    });
  });

  group('BiteBackupCodec archive entry', () {
    test('toArchiveFile names the entry bites.csv', () {
      final file = codec.toArchiveFile([const Bite(id: 1, atMs: 1000)]);
      expect(file.name, BiteBackupCodec.biteFileName);
      expect(file.name, 'bites.csv');
    });

    test('toArchiveFile content is the generated CSV', () {
      final bites = [const Bite(id: 1, atMs: 1234)];
      final file = codec.toArchiveFile(bites);
      final content = String.fromCharCodes(file.content as List<int>);
      expect(content, codec.generateBiteCsv(bites));
    });
  });

  group('BiteBackupCodec parseBiteCsv', () {
    test('reads one instant per at_ms row, preserving order', () {
      const csv = 'at_ms\r\n1000\r\n31000';
      final instants = codec.parseBiteCsv(csv);

      expect(instants.map((d) => d.millisecondsSinceEpoch), [1000, 31000]);
    });

    test('round-trips generateBiteCsv', () {
      final bites = [const Bite(id: 1, atMs: 1000), const Bite(id: 2, atMs: 31000)];
      final instants = codec.parseBiteCsv(codec.generateBiteCsv(bites));

      expect(instants.map((d) => d.millisecondsSinceEpoch), [1000, 31000]);
    });

    test('drops rows whose at_ms is missing or non-integer', () {
      const csv = 'at_ms\r\n1000\r\n\r\nabc\r\n31000';
      final instants = codec.parseBiteCsv(csv);

      expect(instants.map((d) => d.millisecondsSinceEpoch), [1000, 31000]);
    });

    test('an empty CSV parses to no bites', () {
      expect(codec.parseBiteCsv(''), isEmpty);
    });
  });

  group('BiteBackupCodec fromArchive', () {
    test('returns null when the archive has no bite entry', () {
      // A pre-bite, weight-only backup: absence must not be read as "no bites".
      final archive = Archive()
        ..addFile(ArchiveFile('weight.csv', 3, 'a,b'.codeUnits));

      expect(codec.fromArchive(archive), isNull);
    });

    test('returns the parsed bites when the entry is present', () {
      final archive = Archive()
        ..addFile(codec.toArchiveFile([const Bite(id: 1, atMs: 1000)]));

      final instants = codec.fromArchive(archive);
      expect(instants, isNotNull);
      expect(instants!.single.millisecondsSinceEpoch, 1000);
    });

    test('returns an empty list for a present-but-empty bite entry', () {
      // A real snapshot of "no bites", distinct from a missing entry.
      final archive = Archive()..addFile(codec.toArchiveFile([]));

      expect(codec.fromArchive(archive), isEmpty);
    });
  });
}
