import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/generate_service_worker.dart' show precacheManifest;
import '../../tool/web_assets.dart';

void main() {
  late Directory build;

  setUp(() {
    build = Directory.systemTemp.createTempSync('web_build');
    for (final path in [
      'index.html',
      'main.dart.js',
      'canvaskit/canvaskit.wasm',
      'assets/fonts/MaterialIcons-Regular.otf',
      'flutter_service_worker.js',
      'service_worker.js',
      'main.dart.js.map',
      '.last_build_id',
      'CNAME',
      '_headers',
    ]) {
      File('${build.path}/$path')
        ..createSync(recursive: true)
        ..writeAsStringSync(path);
    }
  });

  tearDown(() => build.deleteSync(recursive: true));

  test('precaches the app files, keying index.html as the scope root', () {
    expect(precacheManifest(build), {
      '': sha256Hex('index.html'.codeUnits),
      'assets/fonts/MaterialIcons-Regular.otf':
          sha256Hex('assets/fonts/MaterialIcons-Regular.otf'.codeUnits),
      'canvaskit/canvaskit.wasm':
          sha256Hex('canvaskit/canvaskit.wasm'.codeUnits),
      'main.dart.js': sha256Hex('main.dart.js'.codeUnits),
    });
  });

  test('lists paths in a stable order', () {
    final keys = precacheManifest(build).keys.toList();
    expect(keys, [...keys]..sort());
  });
}
