import 'package:food_locker/features/settings/data/storage_persistence_io.dart'
    if (dart.library.js_interop) 'package:food_locker/features/settings/data/storage_persistence_web.dart'
    as platform;

enum StoragePersistenceState {
  /// Native builds keep data in app-private storage until uninstall, so there
  /// is nothing to ask for.
  notApplicable,

  /// The browser has exempted this origin from eviction.
  persisted,

  /// The browser may delete this origin's data when it runs low on space.
  notPersisted,
}

/// The browser's storage persistence grant, behind a seam so native builds and
/// tests never touch `navigator.storage`.
abstract class StoragePersistence {
  /// Reads the current grant without asking for anything.
  Future<StoragePersistenceState> current();

  /// Asks the browser to exempt this origin from eviction. Some browsers
  /// prompt the user; others decide silently.
  Future<StoragePersistenceState> request();
}

/// The persistence seam for the platform this build targets.
StoragePersistence createStoragePersistence() =>
    platform.createStoragePersistence();
