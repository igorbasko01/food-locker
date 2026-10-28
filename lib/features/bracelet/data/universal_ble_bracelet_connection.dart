import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:food_locker/features/bracelet/data/bracelet_connection.dart';
import 'package:food_locker/features/bracelet/data/bracelet_status.dart';
import 'package:universal_ble/universal_ble.dart';

/// [BraceletConnection] over `universal_ble`. The only file that imports the
/// plugin, so the web build never references it.
class UniversalBleBraceletConnection implements BraceletConnection {
  static const advertisedName = 'BaskoBiteTracker';

  static const _batteryService = '180F';
  static const _batteryLevelChar = '2A19';
  static const _deviceInfoService = '180A';
  static const _manufacturerChar = '2A29';
  static const _modelChar = '2A24';
  static const _trackerService = '78250001-f4b3-4554-946c-39410b5a5210';
  static const _chargingChar = '78250002-f4b3-4554-946c-39410b5a5210';
  static const _powerChar = '78250003-f4b3-4554-946c-39410b5a5210';
  static const _statusChar = '78250004-f4b3-4554-946c-39410b5a5210';

  final _connectionState =
      StreamController<BraceletConnectionState>.broadcast();
  final _batteryLevel = StreamController<int>.broadcast();
  final _charging = StreamController<bool>.broadcast();
  final _status = StreamController<BraceletStatus>.broadcast();

  String? _deviceId;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Future<void> Function()? _endScan;

  @override
  bool get isSupported => true;

  @override
  Stream<BraceletConnectionState> get connectionState =>
      _connectionState.stream;

  @override
  Stream<int> get batteryLevel => _batteryLevel.stream;

  @override
  Stream<bool> get charging => _charging.stream;

  @override
  Stream<BraceletStatus> get status => _status.stream;

  @override
  Stream<List<BraceletScanResult>> scan({required Duration timeout}) {
    final controller = StreamController<List<BraceletScanResult>>();
    final found = <String, BraceletScanResult>{};
    StreamSubscription<BleDevice>? results;
    Timer? timer;
    var ended = false;

    Future<void> end() async {
      if (ended) return;
      ended = true;
      _endScan = null;
      timer?.cancel();
      await results?.cancel();
      try {
        await UniversalBle.stopScan();
      } catch (_) {
        // Already stopped, or Bluetooth went away mid-scan.
      }
      await controller.close();
    }

    controller.onCancel = end;
    controller.onListen = () async {
      _endScan = end;
      try {
        await _ensureReady();
        results = UniversalBle.scanStream.listen((device) {
          // The name rides in the scan response, so the platform filter can
          // only match the advertised Battery Service; the name is checked here.
          if (device.name != advertisedName) return;
          found[device.deviceId] = BraceletScanResult(
            id: device.deviceId,
            name: advertisedName,
            rssi: device.rssi ?? 0,
          );
          controller.add(found.values.toList());
        });
        await UniversalBle.startScan(
          scanFilter: ScanFilter(withServices: [_batteryService]),
        );
        timer = Timer(timeout, end);
      } catch (e) {
        controller.addError(_translate(e, BraceletError.scanFailed));
        await end();
      }
    };
    return controller.stream;
  }

  @override
  Future<void> stopScan() async => _endScan?.call();

  @override
  Future<BraceletDeviceInfo> connect(String id) async {
    _connectionState.add(BraceletConnectionState.connecting);
    try {
      await _ensureReady();
      await UniversalBle.connect(id, timeout: const Duration(seconds: 15));
      _deviceId = id;
      _subscriptions.add(UniversalBle.connectionStream(id).listen((connected) {
        if (!connected) _onDisconnected();
      }));
      await UniversalBle.discoverServices(id);

      final info = BraceletDeviceInfo(
        manufacturer: await _readText(id, _deviceInfoService, _manufacturerChar),
        model: await _readText(id, _deviceInfoService, _modelChar),
      );
      await _follow(id, _batteryService, _batteryLevelChar, (v) {
        if (v.isNotEmpty) _batteryLevel.add(v[0]);
      });
      await _follow(id, _trackerService, _chargingChar, (v) {
        if (v.isNotEmpty) _charging.add(v[0] == 1);
      });
      await _follow(id, _trackerService, _statusChar, (v) {
        final status = parseBraceletStatus(v);
        if (status != null) _status.add(status);
      });

      if (_deviceId == null) {
        throw const BraceletException(BraceletError.connectionFailed);
      }
      _connectionState.add(BraceletConnectionState.connected);
      return info;
    } catch (e) {
      await _cancelSubscriptions();
      _deviceId = null;
      unawaited(UniversalBle.disconnect(id).catchError((_) {}));
      _connectionState.add(BraceletConnectionState.disconnected);
      throw _translate(e, BraceletError.connectionFailed);
    }
  }

  Future<String?> _readText(String id, String service, String char) async {
    try {
      final bytes = await UniversalBle.read(id, service, char);
      return utf8.decode(bytes, allowMalformed: true).trim();
    } catch (_) {
      return null;
    }
  }

  /// Reads the characteristic once, then keeps [onValue] fed with its
  /// notifications.
  Future<void> _follow(
    String id,
    String service,
    String char,
    void Function(List<int>) onValue,
  ) async {
    _subscriptions
        .add(UniversalBle.characteristicValueStream(id, char).listen(onValue));
    onValue(await UniversalBle.read(id, service, char));
    await UniversalBle.subscribeNotifications(id, service, char);
  }

  @override
  Future<void> disconnect() async {
    final id = _deviceId;
    if (id == null) return;
    try {
      await UniversalBle.disconnect(id);
    } finally {
      _onDisconnected();
    }
  }

  @override
  Future<void> shutdown() async {
    final id = _deviceId;
    if (id == null) return;
    try {
      await UniversalBle.write(
          id, _trackerService, _powerChar, Uint8List.fromList([0]));
    } catch (_) {
      // The bracelet may power off before acknowledging the write.
    }
    if (_deviceId == null) return;
    try {
      await connectionState
          .firstWhere((s) => s == BraceletConnectionState.disconnected)
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      await disconnect();
    }
  }

  void _onDisconnected() {
    if (_deviceId == null) return;
    _deviceId = null;
    unawaited(_cancelSubscriptions());
    _connectionState.add(BraceletConnectionState.disconnected);
  }

  Future<void> _cancelSubscriptions() async {
    final subscriptions = List.of(_subscriptions);
    _subscriptions.clear();
    for (final s in subscriptions) {
      await s.cancel();
    }
  }

  /// Asks for the Bluetooth permissions and, if Bluetooth is off, shows
  /// Android's own prompt to turn it on.
  Future<void> _ensureReady() async {
    try {
      await UniversalBle.requestPermissions();
    } catch (e) {
      throw BraceletException(BraceletError.permissionDenied, e.toString());
    }
    final state = await UniversalBle.getBluetoothAvailabilityState();
    switch (state) {
      case AvailabilityState.poweredOn:
        return;
      case AvailabilityState.unsupported:
        throw const BraceletException(BraceletError.bluetoothUnavailable);
      case AvailabilityState.unauthorized:
        throw const BraceletException(BraceletError.permissionDenied);
      default:
        bool enabled;
        try {
          enabled = await UniversalBle.enableBluetooth();
        } catch (_) {
          enabled = false;
        }
        if (!enabled) {
          throw const BraceletException(BraceletError.bluetoothOff);
        }
    }
  }

  static BraceletException _translate(Object e, BraceletError fallback) {
    if (e is BraceletException) return e;
    if (e is UniversalBleException) {
      final error = switch (e.code) {
        UniversalBleErrorCode.bluetoothNotEnabled => BraceletError.bluetoothOff,
        UniversalBleErrorCode.bluetoothNotAvailable =>
          BraceletError.bluetoothUnavailable,
        UniversalBleErrorCode.bluetoothUnauthorized ||
        UniversalBleErrorCode.bluetoothNotAllowed =>
          BraceletError.permissionDenied,
        _ => fallback,
      };
      return BraceletException(error, e.message);
    }
    return BraceletException(fallback, e.toString());
  }
}
