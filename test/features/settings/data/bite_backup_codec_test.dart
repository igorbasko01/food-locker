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
}
