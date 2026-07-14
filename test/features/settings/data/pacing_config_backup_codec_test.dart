import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/settings/data/pacing_config_backup_codec.dart';

void main() {
  const codec = PacingConfigBackupCodec();

  const v1 = PacingConfig(id: 1, effectiveMs: 0, b1S: 15, b2S: 30);
  const v2 = PacingConfig(id: 2, effectiveMs: 5000, b1S: 10, b2S: 20);

  group('PacingConfigBackupCodec CSV logic', () {
    test('generatePacingConfigCsv writes one row per version', () {
      final csv = codec.generatePacingConfigCsv([v1, v2]);

      expect(csv, contains('effective_ms'));
      expect(csv, contains('b1_s'));
      expect(csv, contains('b2_s'));
      expect(csv, contains('5000'));
      expect(csv, contains('10'));
      expect(csv, contains('20'));
    });

    test('generatePacingConfigCsv of no versions is empty', () {
      expect(codec.generatePacingConfigCsv([]), isEmpty);
    });
  });

  group('PacingConfigBackupCodec archive entry', () {
    test('toArchiveFile names the entry pacing_config.csv', () {
      final file = codec.toArchiveFile([v1]);
      expect(file.name, PacingConfigBackupCodec.pacingConfigFileName);
      expect(file.name, 'pacing_config.csv');
    });

    test('toArchiveFile content is the generated CSV', () {
      final file = codec.toArchiveFile([v1, v2]);
      final content = String.fromCharCodes(file.content as List<int>);
      expect(content, codec.generatePacingConfigCsv([v1, v2]));
    });
  });

  group('PacingConfigBackupCodec parsePacingConfigCsv', () {
    test('round-trips generatePacingConfigCsv', () {
      final parsed = codec.parsePacingConfigCsv(
        codec.generatePacingConfigCsv([v1, v2]),
      );

      expect(parsed.map((c) => c.effectiveMs), [0, 5000]);
      expect(parsed.map((c) => c.b1S), [15, 10]);
      expect(parsed.map((c) => c.b2S), [30, 20]);
    });

    test('drops rows missing any of the three integer fields', () {
      const csv = 'effective_ms,b1_s,b2_s\r\n'
          '0,15,30\r\n' // valid
          ',10,20\r\n' // missing effective_ms
          '5000,,20\r\n' // missing b1_s
          '6000,10,abc\r\n' // non-integer b2_s
          '7000,10,20'; // valid
      final parsed = codec.parsePacingConfigCsv(csv);

      expect(parsed.map((c) => c.effectiveMs), [0, 7000]);
    });

    test('an empty CSV parses to no versions', () {
      expect(codec.parsePacingConfigCsv(''), isEmpty);
    });
  });

  group('PacingConfigBackupCodec fromArchive', () {
    test('returns null when the archive has no pacing-config entry', () {
      // A pre-config backup: absence must not be read as "no versions".
      final archive = Archive()
        ..addFile(ArchiveFile('weight.csv', 3, 'a,b'.codeUnits));

      expect(codec.fromArchive(archive), isNull);
    });

    test('returns the parsed versions when the entry is present', () {
      final archive = Archive()..addFile(codec.toArchiveFile([v1, v2]));

      final parsed = codec.fromArchive(archive);
      expect(parsed, isNotNull);
      expect(parsed!.map((c) => c.effectiveMs), [0, 5000]);
    });

    test('returns an empty list for a present-but-empty entry', () {
      // A real snapshot of "no versions", distinct from a missing entry.
      final archive = Archive()..addFile(codec.toArchiveFile([]));

      expect(codec.fromArchive(archive), isEmpty);
    });
  });
}
