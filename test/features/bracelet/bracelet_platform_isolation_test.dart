import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the flutter_blue_plus implementation imports the plugin', () {
    final importers = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f
            .readAsStringSync()
            .contains('package:flutter_blue_plus/'))
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toList();
    expect(importers, [
      'lib/features/bracelet/data/flutter_blue_plus_bracelet_connection.dart',
    ]);
  });

  test('the web seam never reaches the plugin implementation', () {
    final web = File('lib/features/bracelet/data/bracelet_connection_web.dart')
        .readAsStringSync();
    expect(web, isNot(contains('flutter_blue_plus')));
  });
}
