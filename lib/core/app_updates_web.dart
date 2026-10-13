import 'dart:js_interop_unsafe';

import 'package:food_locker/core/app_updates.dart' show AppUpdates;
import 'package:web/web.dart' as web;

AppUpdates createAppUpdates() => WebAppUpdates();

/// Reads the signal `web/flutter_bootstrap.js` raises when a new service
/// worker takes over a page an older one was serving.
class WebAppUpdates implements AppUpdates {
  static const _flag = 'foodLockerUpdateReady';
  static const _event = 'foodlocker-update-ready';

  @override
  late final Future<void> ready = web.window.has(_flag)
      ? Future.value()
      : const web.EventStreamProvider<web.Event>(_event)
          .forTarget(web.window)
          .first;

  @override
  void reload() => web.window.location.reload();
}
