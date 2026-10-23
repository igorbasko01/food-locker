import 'dart:async';

import 'package:food_locker/features/bracelet/data/bracelet_connection.dart';
import 'package:food_locker/features/bracelet/data/bracelet_status.dart';

/// A [BraceletConnection] driven by the test: scans emit [found] (or
/// [scanError]) and then end, unless [holdScans] keeps them running until
/// [finishScan]; connects succeed with [deviceInfo] unless [connectError] is
/// set, and the `emit*` methods stand in for the bracelet's notifications.
class FakeBraceletConnection implements BraceletConnection {
  FakeBraceletConnection({this.isSupported = true});

  @override
  final bool isSupported;

  List<BraceletScanResult> found = const [];
  bool holdScans = false;
  BraceletException? scanError;
  BraceletException? connectError;
  BraceletDeviceInfo deviceInfo = const BraceletDeviceInfo(
    manufacturer: 'Seeed Studio',
    model: 'XIAO nRF52840 Sense',
  );

  String? connectedId;
  int shutdownCount = 0;

  final _state = StreamController<BraceletConnectionState>.broadcast();
  final _battery = StreamController<int>.broadcast();
  final _charging = StreamController<bool>.broadcast();
  final _status = StreamController<BraceletStatus>.broadcast();
  StreamController<List<BraceletScanResult>>? _scan;

  @override
  Stream<List<BraceletScanResult>> scan({required Duration timeout}) {
    final controller = _scan = StreamController<List<BraceletScanResult>>();
    controller.onListen = () {
      if (scanError != null) {
        controller.addError(scanError!);
      } else if (found.isNotEmpty) {
        controller.add(found);
      }
      if (holdScans) return;
      controller.close();
    };
    return controller.stream;
  }

  /// Ends the running scan, as its timeout would.
  Future<void> finishScan() async => _scan?.close();

  @override
  Future<void> stopScan() => finishScan();

  @override
  Future<BraceletDeviceInfo> connect(String id) async {
    _state.add(BraceletConnectionState.connecting);
    if (connectError != null) {
      _state.add(BraceletConnectionState.disconnected);
      throw connectError!;
    }
    connectedId = id;
    _state.add(BraceletConnectionState.connected);
    return deviceInfo;
  }

  @override
  Future<void> disconnect() async => dropLink();

  @override
  Future<void> shutdown() async {
    shutdownCount++;
    dropLink();
  }

  /// The link going down, whoever caused it.
  void dropLink() {
    connectedId = null;
    _state.add(BraceletConnectionState.disconnected);
  }

  void emitBattery(int percent) => _battery.add(percent);
  void emitCharging(bool charging) => _charging.add(charging);
  void emitStatus(BraceletStatus status) => _status.add(status);

  @override
  Stream<BraceletConnectionState> get connectionState => _state.stream;

  @override
  Stream<int> get batteryLevel => _battery.stream;

  @override
  Stream<bool> get charging => _charging.stream;

  @override
  Stream<BraceletStatus> get status => _status.stream;
}
