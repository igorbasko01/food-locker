import 'package:archive/archive.dart';
import 'package:food_locker/core/csv_serializer.dart';

/// The profile facts a backup carries. A type of its own rather than a bare
/// `double?` so an import can tell an archive that says "no height recorded"
/// from an archive that doesn't describe a profile at all.
class ProfileBackup {
  final double? heightCm;

  const ProfileBackup({required this.heightCm});
}

/// CSV backup logic for the profile preferences.
///
/// The height lives in `shared_preferences` rather than in either data store,
/// so without this entry it would survive a "Clear All Data" and vanish on a
/// restore. This codec turns it into a `profile.csv` entry that
/// `SerializationService` packs into the same zip as the other datasets.
///
/// Only the height is carried: the measurement system is how this device shows
/// figures, not a fact about the user worth moving between installs.
class ProfileBackupCodec {
  /// The profile dataset's entry inside a backup zip.
  static const String profileFileName = 'profile.csv';

  static const String heightColumn = 'height_cm';

  const ProfileBackupCodec();

  /// The profile CSV packaged as a single [ArchiveFile], so it can be added to
  /// a shared archive that also carries the weight, bite and pacing CSVs.
  ArchiveFile toArchiveFile(double? heightCm) {
    final csvContent = generateProfileCsv(heightCm);
    return ArchiveFile(
      profileFileName,
      csvContent.length,
      csvContent.codeUnits,
    );
  }

  /// One row, exported whether or not a height was ever entered — an unset
  /// height is an empty cell, so a restore reproduces "not answered" rather
  /// than leaving whatever the device happened to hold.
  String generateProfileCsv(double? heightCm) {
    return CsvSerializer.toCSV([
      {heightColumn: heightCm},
    ]);
  }

  /// The profile carried by a decoded [archive], or null when the archive has
  /// no profile entry at all.
  ///
  /// The null vs. empty distinction is load-bearing on import, as it is for the
  /// bite and pacing entries: an older backup doesn't describe the profile and
  /// must leave the stored height untouched, whereas a present entry is a full
  /// snapshot and replaces it.
  ProfileBackup? fromArchive(Archive archive) {
    for (final file in archive) {
      if (file.isFile && file.name == profileFileName) {
        final content = String.fromCharCodes(file.content as List<int>);
        return parseProfileCsv(content);
      }
    }
    return null;
  }

  /// The first row's height, or a profile with no height when the entry holds
  /// no row, an empty cell, or something unparseable — the entry is present
  /// either way, and a present entry is a snapshot.
  ProfileBackup parseProfileCsv(String csv) {
    for (final item in CsvSerializer.fromCSV(csv)) {
      final raw = item[heightColumn];
      final height = raw is num
          ? raw.toDouble()
          : double.tryParse(raw?.toString() ?? '');
      return ProfileBackup(
        heightCm: height != null && height > 0 ? height : null,
      );
    }
    return const ProfileBackup(heightCm: null);
  }
}
