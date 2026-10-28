import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the universal_ble implementation imports the plugin', () {
    final importers = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f
            .readAsStringSync()
            .contains('package:universal_ble/'))
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toList();
    expect(importers, [
      'lib/features/bracelet/data/universal_ble_bracelet_connection.dart',
    ]);
  });

  test('the web seam never reaches the plugin implementation', () {
    final web = File('lib/features/bracelet/data/bracelet_connection_web.dart')
        .readAsStringSync();
    expect(web, isNot(contains('universal_ble')));
  });
}
