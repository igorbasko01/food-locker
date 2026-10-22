import 'package:food_locker/features/bracelet/data/bracelet_connection_io.dart'
    if (dart.library.js_interop) 'package:food_locker/features/bracelet/data/bracelet_connection_web.dart'
    as platform;
import 'package:food_locker/features/bracelet/data/bracelet_status.dart';

enum BraceletConnectionState { disconnected, connecting, connected }

/// A bracelet found by [BraceletConnection.scan].
class BraceletScanResult {
  const BraceletScanResult({
    required this.id,
    required this.name,
    required this.rssi,
  });

  final String id;
  final String name;

  /// Signal strength in dBm.
  final int rssi;
}

/// The bracelet's Device Information service.
class BraceletDeviceInfo {
  const BraceletDeviceInfo({this.manufacturer, this.model});

  final String? manufacturer;
  final String? model;
}

enum BraceletError {
  permissionDenied,
  bluetoothOff,
  bluetoothUnavailable,
  scanFailed,
  connectionFailed,
  connectionLost,
}

class BraceletException implements Exception {
  const BraceletException(this.error, [this.detail]);

  final BraceletError error;
  final String? detail;

  @override
  String toString() =>
      'BraceletException(${error.name}${detail == null ? '' : ': $detail'})';
}

/// The BLE link to one bite-tracker bracelet, behind a seam so the web build
/// and tests never reach a Bluetooth plugin.
abstract class BraceletConnection {
  /// False where there is no bracelet support at all (web, non-Android).
  bool get isSupported;

  /// Scans for nearby bracelets, emitting everything found so far each time
  /// the list changes, and closes when [timeout] passes or [stopScan] is
  /// called. Errors are [BraceletException]s.
  Stream<List<BraceletScanResult>> scan({required Duration timeout});

  Future<void> stopScan();

  /// Connects to the bracelet [id] and subscribes to its notifications.
  /// Throws a [BraceletException] if it cannot.
  Future<BraceletDeviceInfo> connect(String id);

  Future<void> disconnect();

  /// Switches the bracelet off; the link drops as it does.
  Future<void> shutdown();

  /// Every state change, including a link the bracelet dropped on its own.
  Stream<BraceletConnectionState> get connectionState;

  /// Battery level in percent.
  Stream<int> get batteryLevel;

  Stream<bool> get charging;

  Stream<BraceletStatus> get status;
}

/// The bracelet connection for the platform this build targets.
BraceletConnection createBraceletConnection() =>
    platform.createBraceletConnection();

/// Where bracelets are not supported: never scans or connects.
class UnsupportedBraceletConnection implements BraceletConnection {
  const UnsupportedBraceletConnection();

  @override
  bool get isSupported => false;

  @override
  Stream<List<BraceletScanResult>> scan({required Duration timeout}) =>
      const Stream.empty();

  @override
  Future<void> stopScan() async {}

  @override
  Future<BraceletDeviceInfo> connect(String id) async =>
      throw const BraceletException(BraceletError.bluetoothUnavailable);

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> shutdown() async {}

  @override
  Stream<BraceletConnectionState> get connectionState => const Stream.empty();

  @override
  Stream<int> get batteryLevel => const Stream.empty();

  @override
  Stream<bool> get charging => const Stream.empty();

  @override
  Stream<BraceletStatus> get status => const Stream.empty();
}
