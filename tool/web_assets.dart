import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

/// A file in `web/` downloaded from the GitHub release of the pub [package]
/// it belongs to; `{version}` in [url] is that package's resolved version.
typedef VendoredAsset = ({String package, String url});

const vendoredAssets = <String, VendoredAsset>{
  'drift_worker.js': (
    package: 'drift',
    url: 'https://github.com/simolus3/drift/releases/download/'
        'drift-{version}/drift_worker.js',
  ),
  'sqlite3.wasm': (
    package: 'sqlite3',
    url: 'https://github.com/simolus3/sqlite3.dart/releases/download/'
        'sqlite3-{version}/sqlite3.wasm',
  ),
};

/// Records the package version and sha256 each vendored asset was fetched at.
const manifestPath = 'tool/vendored_web_assets.json';

String lockedVersion(String package) {
  final lock = loadYaml(File('pubspec.lock').readAsStringSync()) as YamlMap;
  return (lock['packages'] as YamlMap)[package]['version'] as String;
}

String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();
