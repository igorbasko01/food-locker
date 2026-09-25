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
}
