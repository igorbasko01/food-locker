import 'package:food_locker/features/settings/data/storage_persistence.dart';

StoragePersistence createStoragePersistence() =>
    const NativeStoragePersistence();

class NativeStoragePersistence implements StoragePersistence {
  const NativeStoragePersistence();

  @override
  Future<StoragePersistenceState> current() async =>
      StoragePersistenceState.notApplicable;

  @override
  Future<StoragePersistenceState> request() async =>
      StoragePersistenceState.notApplicable;
}
