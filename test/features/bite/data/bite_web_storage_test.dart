import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';

void main() {
  group('describeWebStorage', () {
    test('names the chosen tier when nothing is missing', () {
      expect(
        describeWebStorage(WasmStorageImplementation.opfsShared, {}),
        'Bite store on web uses opfsShared (no missing browser features)',
      );
    });

    test('lists every missing browser feature', () {
      expect(
        describeWebStorage(WasmStorageImplementation.unsafeIndexedDb, {
          MissingBrowserFeature.sharedWorkers,
          MissingBrowserFeature.sharedArrayBuffers,
        }),
        'Bite store on web uses unsafeIndexedDb '
        '(missing browser features: sharedWorkers, sharedArrayBuffers)',
      );
    });
  });
}
