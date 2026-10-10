import 'dart:async';

import 'package:food_locker/core/app_updates.dart' show AppUpdates;

AppUpdates createAppUpdates() => NativeAppUpdates();

/// Native builds update through the app store, never while running.
class NativeAppUpdates implements AppUpdates {
  @override
  final Future<void> ready = Completer<void>().future;

  @override
  void reload() {}
}
