import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:food_locker/features/bracelet/data/bracelet_connection.dart';
import 'package:food_locker/features/bracelet/data/bracelet_status.dart';

/// [BraceletConnection] over `flutter_blue_plus`. The only file that imports
/// the plugin, so the web build never references it.
class FlutterBluePlusBraceletConnection implements BraceletConnection {
  static const advertisedName = 'BaskoBiteTracker';

  static final _batteryService = Guid('180F');
  static final _batteryLevelChar = Guid('2A19');
  static final _deviceInfoService = Guid('180A');
  static final _manufacturerChar = Guid('2A29');
  static final _modelChar = Guid('2A24');
  static final _trackerService = Guid('78250001-f4b3-4554-946c-39410b5a5210');
  static final _chargingChar = Guid('78250002-f4b3-4554-946c-39410b5a5210');
  static final _powerChar = Guid('78250003-f4b3-4554-946c-39410b5a5210');
  static final _statusChar = Guid('78250004-f4b3-4554-946c-39410b5a5210');

  final _connectionState =
      StreamController<BraceletConnectionState>.broadcast();
  final _batteryLevel = StreamController<int>.broadcast();
  final _charging = StreamController<bool>.broadcast();
  final _status = StreamController<BraceletStatus>.broadcast();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _power;
  final List<StreamSubscription<Object?>> _subscriptions = [];

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
    controller.onListen = () async {
      StreamSubscription<List<ScanResult>>? results;
      try {
        await _ensureAdapterOn();
        results = FlutterBluePlus.onScanResults.listen(
          (all) => controller.add(_bracelets(all)),
          onError: (Object e) =>
              controller.addError(_translate(e, BraceletError.scanFailed)),
        );
        // The name rides in the scan response, so the platform filter can
        // only match the advertised Battery Service; the name is checked here.
        await FlutterBluePlus.startScan(
          withServices: [_batteryService],
          timeout: timeout,
        );
        await FlutterBluePlus.isScanning.where((scanning) => !scanning).first;
      } catch (e) {
        controller.addError(_translate(e, BraceletError.scanFailed));
      }
      await results?.cancel();
      await controller.close();
    };
    return controller.stream;
  }

  List<BraceletScanResult> _bracelets(List<ScanResult> all) => [
        for (final r in all)
          if (r.advertisementData.advName == advertisedName ||
              r.device.advName == advertisedName)
            BraceletScanResult(
              id: r.device.remoteId.str,
              name: advertisedName,
              rssi: r.rssi,
            ),
      ];

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  Future<BraceletDeviceInfo> connect(String id) async {
    _connectionState.add(BraceletConnectionState.connecting);
    final device = BluetoothDevice.fromId(id);
    try {
      await _ensureAdapterOn();
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
        mtu: null,
      );
      _device = device;
      final services = await device.discoverServices();
      BluetoothCharacteristic characteristic(Guid service, Guid char) =>
          services
              .firstWhere((s) => s.uuid == service)
              .characteristics
              .firstWhere((c) => c.uuid == char);

      final info = BraceletDeviceInfo(
        manufacturer: await _readText(
            characteristic(_deviceInfoService, _manufacturerChar)),
        model: await _readText(characteristic(_deviceInfoService, _modelChar)),
      );
      await _follow(characteristic(_batteryService, _batteryLevelChar), (v) {
        if (v.isNotEmpty) _batteryLevel.add(v[0]);
      });
      await _follow(characteristic(_trackerService, _chargingChar), (v) {
        if (v.isNotEmpty) _charging.add(v[0] == 1);
      });
      await _follow(characteristic(_trackerService, _statusChar), (v) {
        final status = parseBraceletStatus(v);
        if (status != null) _status.add(status);
      });
      _power = characteristic(_trackerService, _powerChar);

      _subscriptions.add(device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) _onDisconnected();
      }));
      _connectionState.add(BraceletConnectionState.connected);
      return info;
    } catch (e) {
      await _cancelSubscriptions();
      _device = null;
      _power = null;
      unawaited(device.disconnect().catchError((_) {}));
      _connectionState.add(BraceletConnectionState.disconnected);
      throw _translate(e, BraceletError.connectionFailed);
    }
  }

  Future<String?> _readText(BluetoothCharacteristic c) async {
    try {
      return utf8.decode(await c.read(), allowMalformed: true).trim();
    } catch (_) {
      return null;
    }
  }

  /// Reads [c] once, then keeps [onValue] fed with its notifications.
  Future<void> _follow(
    BluetoothCharacteristic c,
    void Function(List<int>) onValue,
  ) async {
    _subscriptions.add(c.onValueReceived.listen(onValue));
    await c.read();
    await c.setNotifyValue(true);
  }

  @override
  Future<void> disconnect() async {
    final device = _device;
    if (device == null) return;
    try {
      await device.disconnect();
    } finally {
      _onDisconnected();
    }
  }

  @override
  Future<void> shutdown() async {
    final power = _power;
    if (power == null) return;
    try {
      await power.write([0]);
    } catch (_) {
      // The bracelet may power off before acknowledging the write.
    }
    if (_device == null) return;
    try {
      await connectionState
          .firstWhere((s) => s == BraceletConnectionState.disconnected)
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      await disconnect();
    }
  }

  void _onDisconnected() {
    if (_device == null) return;
    _device = null;
    _power = null;
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

  Future<void> _ensureAdapterOn() async {
    if (!await FlutterBluePlus.isSupported) {
      throw const BraceletException(BraceletError.bluetoothUnavailable);
    }
    final state = await FlutterBluePlus.adapterState
        .firstWhere((s) => s != BluetoothAdapterState.unknown)
        .timeout(const Duration(seconds: 3),
            onTimeout: () => BluetoothAdapterState.unknown);
    if (state == BluetoothAdapterState.on) return;
    if (state == BluetoothAdapterState.unauthorized) {
      throw const BraceletException(BraceletError.permissionDenied);
    }
    try {
      // Shows Android's own "turn Bluetooth on?" prompt, asking for the
      // connect permission first if it is missing.
      await FlutterBluePlus.turnOn();
    } catch (e) {
      throw _translate(e, BraceletError.bluetoothOff);
    }
  }

  static BraceletException _translate(Object e, BraceletError fallback) {
    if (e is BraceletException) return e;
    final text = e.toString();
    if (text.contains('Permission')) {
      return BraceletException(BraceletError.permissionDenied, text);
    }
    if (text.contains('must be turned on') || text.contains('adapterIsOff')) {
      return BraceletException(BraceletError.bluetoothOff, text);
    }
    return BraceletException(fallback, text);
  }
}
