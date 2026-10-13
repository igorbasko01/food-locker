import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/web_assets.dart';

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

  test('web/flutter_bootstrap.js registers our worker, not Flutter\'s stub', () {
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();
    expect(bootstrap, contains('{{flutter_js}}'));
    expect(bootstrap, contains('{{flutter_build_config}}'));
    expect(bootstrap, isNot(contains('serviceWorkerSettings')));
    expect(bootstrap, contains("register('service_worker.js')"));
  });

  for (final path in [
    '.github/workflows/deploy_web.yml',
    '.github/workflows/flutter_ci.yml',
  ]) {
    test('$path generates the service worker after the web build', () {
      final workflow = File(path).readAsStringSync();
      final build = workflow.indexOf('flutter build web');
      final generate =
          workflow.indexOf('dart run tool/generate_service_worker.dart');
      expect(build, isNonNegative);
      expect(generate, greaterThan(build));
    });
  }

  group('.github/workflows/deploy_web.yml', () {
    final workflow =
        File('.github/workflows/deploy_web.yml').readAsStringSync();

    test('deploys on a published release', () {
      expect(workflow, contains('release:\n    types: [published]'));
      expect(workflow, contains('github.event.release.prerelease == false'));
    });

    test('builds at the domain root with CanvasKit self-hosted', () {
      expect(workflow, contains('flutter build web'));
      expect(workflow, contains('--base-href=/ '));
      expect(workflow, contains('--no-web-resources-cdn'));
    });

    test('publishes build/web to the production Cloudflare Pages branch', () {
      expect(workflow, contains('cloudflare/wrangler-action@'));
      expect(
          workflow,
          contains(
              'pages deploy build/web --project-name=food-locker --branch=main'));
      expect(workflow, contains(r'secrets.CLOUDFLARE_API_TOKEN'));
      expect(workflow, contains(r'secrets.CLOUDFLARE_ACCOUNT_ID'));
    });
  });

  group('vendored web assets', () {
    const update = 'run `dart run tool/update_web_assets.dart`';
    final manifest =
        jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

    test('the manifest covers every vendored asset', () {
      expect(manifest.keys, unorderedEquals(vendoredAssets.keys));
    });

    for (final MapEntry(key: file, value: asset) in vendoredAssets.entries) {
      test('web/$file matches the resolved ${asset.package} version', () {
        final entry = manifest[file] as Map<String, dynamic>;
        expect(entry['version'], lockedVersion(asset.package),
            reason: '${asset.package} moved in pubspec.lock; $update');
        expect(sha256Hex(File('web/$file').readAsBytesSync()), entry['sha256'],
            reason: 'web/$file differs from what the manifest records; $update');
      });
    }
  });
}
