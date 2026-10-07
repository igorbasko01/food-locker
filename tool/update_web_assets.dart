import 'dart:convert';
import 'dart:io';

import 'web_assets.dart';

/// Re-downloads every vendored web asset at the version `pubspec.lock`
/// resolves and rewrites the manifest. Run after any `flutter pub upgrade`:
///
///     dart run tool/update_web_assets.dart
Future<void> main() async {
  final client = HttpClient();
  final manifest = <String, Object>{};
  try {
    for (final MapEntry(key: file, value: asset) in vendoredAssets.entries) {
      final version = lockedVersion(asset.package);
      final url = Uri.parse(asset.url.replaceAll('{version}', version));
      final response = await (await client.getUrl(url)).close();
      if (response.statusCode != HttpStatus.ok) {
        stderr.writeln('$url: HTTP ${response.statusCode}');
        exitCode = 1;
        return;
      }
      final bytes = await response.expand((chunk) => chunk).toList();
      File('web/$file').writeAsBytesSync(bytes);
      manifest[file] = {
        'package': asset.package,
        'version': version,
        'sha256': sha256Hex(bytes),
      };
      stdout.writeln('web/$file <- ${asset.package} $version');
    }
    File(manifestPath).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    );
  } finally {
    client.close();
  }
}
