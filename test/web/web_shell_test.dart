import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('web/manifest.json', () {
    final manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;

    test('starts and scopes at the domain root to match --base-href=/', () {
      expect(manifest['start_url'], '/');
      expect(manifest['scope'], '/');
    });

    test('lists icons that exist, including maskable ones', () {
      final icons = (manifest['icons'] as List).cast<Map<String, dynamic>>();
      for (final icon in icons) {
        expect(File('web/${icon['src']}').existsSync(), isTrue,
            reason: icon['src'] as String);
      }
      expect(icons.map((i) => i['sizes']), containsAll(['192x192', '512x512']));
      expect(icons.where((i) => i['purpose'] == 'maskable'), isNotEmpty);
    });
  });

  test('web/CNAME pins the Pages custom domain', () {
    expect(File('web/CNAME').readAsStringSync().trim(),
        'foodlocker.baskorp.com');
  });

  test('web/.nojekyll exists so Pages skips Jekyll', () {
    expect(File('web/.nojekyll').existsSync(), isTrue);
  });

  test('web/index.html takes its base href from the build', () {
    expect(File('web/index.html').readAsStringSync(),
        contains('<base href="\$FLUTTER_BASE_HREF">'));
  });

  group('vendored Drift web assets', () {
    // Re-download both from the matching GitHub releases whenever a
    // dependency bump moves either version.
    const vendoredDrift = '2.34.1';
    const vendoredSqlite3 = '3.1.7';

    String lockedVersion(String package) {
      final lock = File('pubspec.lock').readAsStringSync();
      final match = RegExp(
        '\\n  $package:\\n(?:    .*\\n)*?    version: "([^"]+)"',
      ).firstMatch(lock);
      return match!.group(1)!;
    }

    test('match the resolved drift and sqlite3 versions', () {
      expect(lockedVersion('drift'), vendoredDrift,
          reason: 'update web/drift_worker.js from drift-${lockedVersion('drift')}');
      expect(lockedVersion('sqlite3'), vendoredSqlite3,
          reason:
              'update web/sqlite3.wasm from sqlite3-${lockedVersion('sqlite3')}');
    });

    test('web/sqlite3.wasm is a WebAssembly module', () {
      final bytes = File('web/sqlite3.wasm').readAsBytesSync();
      expect(bytes.sublist(0, 4), [0x00, 0x61, 0x73, 0x6d]);
    });

    test('web/drift_worker.js is a compiled Dart worker', () {
      expect(File('web/drift_worker.js').readAsStringSync(),
          startsWith('(function dartProgram()'));
    });
  });
}
