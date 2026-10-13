import 'dart:convert';
import 'dart:io';

import 'web_assets.dart';

/// Writes `service_worker.js` into a finished web build, precaching every
/// file in it so the PWA opens offline. Run after `flutter build web`:
///
///     dart run tool/generate_service_worker.dart [build/web]
void main(List<String> args) {
  final build = Directory(
      args.isEmpty ? 'build/web' : args.single.replaceAll(RegExp(r'/+$'), ''));
  if (!build.existsSync()) {
    stderr.writeln('${build.path} not found; run `flutter build web` first');
    exitCode = 1;
    return;
  }
  final manifest = precacheManifest(build);
  final template =
      File('tool/service_worker.template.js').readAsStringSync();
  File('${build.path}/$serviceWorkerFile').writeAsStringSync(
    'const PRECACHE = ${const JsonEncoder.withIndent('  ').convert(manifest)};\n\n'
    '$template',
  );
  stdout.writeln(
      '${build.path}/$serviceWorkerFile precaches ${manifest.length} files');
}

const serviceWorkerFile = 'service_worker.js';

/// Maps each file the app may load, relative to [build], to its sha256.
/// `index.html` is keyed as `''`, the scope root it is served at.
Map<String, String> precacheManifest(Directory build) {
  final entries = <String, String>{};
  for (final file in build.listSync(recursive: true).whereType<File>()) {
    final path = file.path
        .substring(build.path.length + 1)
        .replaceAll(Platform.pathSeparator, '/');
    if (_skip(path)) continue;
    entries[path == 'index.html' ? '' : path] =
        sha256Hex(file.readAsBytesSync());
  }
  return Map.fromEntries(
      entries.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
}

bool _skip(String path) {
  final name = path.split('/').last;
  return name.startsWith('.') ||
      name.endsWith('.map') ||
      name.endsWith('.symbols') ||
      const {
        serviceWorkerFile,
        'flutter_service_worker.js',
        'CNAME',
        '_headers',
        '_redirects',
      }.contains(path);
}
