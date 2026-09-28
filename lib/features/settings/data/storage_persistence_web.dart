import 'dart:js_interop';

import 'package:food_locker/features/settings/data/storage_persistence.dart';
import 'package:web/web.dart' as web;

StoragePersistence createStoragePersistence() => const WebStoragePersistence();

class WebStoragePersistence implements StoragePersistence {
  const WebStoragePersistence();

  @override
  Future<StoragePersistenceState> current() =>
      _ask(() => web.window.navigator.storage.persisted());

  @override
  Future<StoragePersistenceState> request() =>
      _ask(() => web.window.navigator.storage.persist());

  // A browser without the Storage API (an insecure context, an older Safari)
  // can still evict, so a call that fails reads as not persisted.
  Future<StoragePersistenceState> _ask(
    JSPromise<JSBoolean> Function() call,
  ) async {
    try {
      final granted = (await call().toDart).toDart;
      return granted
          ? StoragePersistenceState.persisted
          : StoragePersistenceState.notPersisted;
    } catch (_) {
      return StoragePersistenceState.notPersisted;
    }
  }
}
