import 'package:food_locker/core/app_updates_io.dart'
    if (dart.library.js_interop) 'package:food_locker/core/app_updates_web.dart'
    as platform;

/// New deploys of the web build, behind a seam so native builds and tests
/// never touch the service worker.
abstract class AppUpdates {
  /// Completes once a newer deploy has been installed and a reload would run
  /// it. Never completes on native builds.
  Future<void> get ready;

  /// Reloads the page into the newer deploy.
  void reload();
}

/// The update seam for the platform this build targets.
AppUpdates createAppUpdates() => platform.createAppUpdates();
