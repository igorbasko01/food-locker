import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/settings/data/profile_backup_codec.dart';

/// The profile entry's contract: a height round-trips, an archive without the
/// entry says so with null, and an archive carrying an entry is a snapshot even
/// when the height in it is blank.
void main() {
  const codec = ProfileBackupCodec();

  Archive archiveWith(double? heightCm) =>
      Archive()..addFile(codec.toArchiveFile(heightCm));

  group('generateProfileCsv', () {
    test('names the column and carries the height', () {
      final csv = codec.generateProfileCsv(178.5);

      expect(csv, contains(ProfileBackupCodec.heightColumn));
      expect(csv, contains('178.5'));
    });
  });

  group('fromArchive', () {
    test('reads back the exported height', () {
      final profile = codec.fromArchive(archiveWith(178.5));

      expect(profile, isNotNull);
      expect(profile!.heightCm, 178.5);
    });

    test('an unset height exports and reads back as unset', () {
      final profile = codec.fromArchive(archiveWith(null));

      expect(profile, isNotNull);
      expect(profile!.heightCm, isNull);
    });

    test('an archive without a profile entry returns null', () {
      final archive = Archive()
        ..addFile(ArchiveFile('weight.csv', 4, 'date'.codeUnits));

      expect(codec.fromArchive(archive), isNull);
    });

    test('an empty profile entry is still a snapshot', () {
      final archive = Archive()
        ..addFile(ArchiveFile(ProfileBackupCodec.profileFileName, 0, <int>[]));

      final profile = codec.fromArchive(archive);

      expect(profile, isNotNull);
      expect(profile!.heightCm, isNull);
    });
  });

  group('parseProfileCsv', () {
    test('drops a value that is not a number', () {
      expect(codec.parseProfileCsv('height_cm\r\ntall').heightCm, isNull);
    });

    test('drops a non-positive height', () {
      expect(codec.parseProfileCsv('height_cm\r\n0').heightCm, isNull);
      expect(codec.parseProfileCsv('height_cm\r\n-12').heightCm, isNull);
    });

    test('reads a whole-number height', () {
      expect(codec.parseProfileCsv('height_cm\r\n178').heightCm, 178.0);
    });
  });
}
