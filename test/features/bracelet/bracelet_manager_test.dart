import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bracelet/data/bracelet_connection.dart';
import 'package:food_locker/features/bracelet/data/bracelet_manager.dart';
import 'package:food_locker/features/bracelet/data/bracelet_status.dart';

import '../../helpers/fake_bracelet_connection.dart';

const _band = BraceletScanResult(id: 'AA:BB', name: 'BaskoBiteTracker', rssi: -60);

void main() {
  late FakeBraceletConnection connection;
  late BraceletManager manager;

  setUp(() {
    connection = FakeBraceletConnection()..found = const [_band];
    manager = BraceletManager(connection);
  });

  tearDown(() => manager.dispose());

  Future<void> connect() async {
    await manager.connect(_band);
    await pumpEventQueue();
  }

  test('reports support from the connection', () {
    expect(manager.isSupported, isTrue);
    expect(BraceletManager(FakeBraceletConnection(isSupported: false)).isSupported,
        isFalse);
  });

  test('lists the bracelets a scan finds', () async {
    connection.holdScans = true;
    final done = manager.startScan();
    await pumpEventQueue();
    expect(manager.isScanning, isTrue);
    expect(manager.scanResults, [_band]);

    await connection.finishScan();
    await done;
    expect(manager.isScanning, isFalse);
    expect(manager.hasScanned, isTrue);
  });

  test('a scan that finds nothing ends with no results and no error', () async {
    connection.found = const [];
    await manager.startScan();
    expect(manager.scanResults, isEmpty);
    expect(manager.hasScanned, isTrue);
    expect(manager.error, isNull);
  });

  test('surfaces a denied permission from the scan', () async {
    connection.scanError =
        const BraceletException(BraceletError.permissionDenied);
    await manager.startScan();
    expect(manager.error, BraceletError.permissionDenied);
    expect(manager.isScanning, isFalse);
  });

  test('surfaces Bluetooth being off', () async {
    connection.scanError = const BraceletException(BraceletError.bluetoothOff);
    await manager.startScan();
    expect(manager.error, BraceletError.bluetoothOff);
  });

  test('connecting fills in the device and what it reports', () async {
    await manager.startScan();
    await connect();

    expect(connection.connectedId, 'AA:BB');
    expect(manager.connectionState, BraceletConnectionState.connected);
    expect(manager.isConnected, isTrue);
    expect(manager.deviceName, 'BaskoBiteTracker');
    expect(manager.manufacturer, 'Seeed Studio');
    expect(manager.model, 'XIAO nRF52840 Sense');

    connection
      ..emitBattery(87)
      ..emitCharging(true)
      ..emitStatus(const BraceletStatus(
        uptime: Duration(minutes: 72),
        resetReason: ResetReason.watchdog,
      ));
    await pumpEventQueue();
    expect(manager.batteryPercent, 87);
    expect(manager.isCharging, isTrue);
    expect(manager.uptime, const Duration(minutes: 72));
    expect(manager.resetReason, ResetReason.watchdog);

    connection.emitBattery(86);
    await pumpEventQueue();
    expect(manager.batteryPercent, 86);
  });

  test('a failed connect returns to disconnected with an error', () async {
    connection.connectError =
        const BraceletException(BraceletError.connectionFailed);
    await connect();
    expect(manager.connectionState, BraceletConnectionState.disconnected);
    expect(manager.error, BraceletError.connectionFailed);
    expect(manager.deviceName, isNull);
  });

  test('disconnect drops the link and clears the readings', () async {
    await connect();
    connection.emitBattery(50);
    await pumpEventQueue();

    await manager.disconnect();
    await pumpEventQueue();
    expect(manager.connectionState, BraceletConnectionState.disconnected);
    expect(manager.batteryPercent, isNull);
    expect(manager.deviceName, isNull);
    expect(manager.error, isNull);
  });

  test('shutdown asks the bracelet to power off and ends disconnected',
      () async {
    await connect();
    await manager.shutdown();
    await pumpEventQueue();
    expect(connection.shutdownCount, 1);
    expect(manager.connectionState, BraceletConnectionState.disconnected);
    expect(manager.error, isNull);
  });

  test('an unexpected drop shows as disconnected with connectionLost',
      () async {
    await connect();
    connection.dropLink();
    await pumpEventQueue();
    expect(manager.isConnected, isFalse);
    expect(manager.error, BraceletError.connectionLost);
  });

  test('notifies listeners on state changes', () async {
    var notifications = 0;
    manager.addListener(() => notifications++);
    await connect();
    expect(notifications, greaterThan(0));
  });
}
