import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:food_locker/features/bracelet/data/bracelet_connection.dart';
import 'package:food_locker/features/bracelet/data/bracelet_status.dart';

/// UI-facing state for the bite-tracker bracelet: the scan, the link, and
/// everything the band reports while connected. Nothing here is persisted.
class BraceletManager extends ChangeNotifier {
  BraceletManager(
    this._connection, {
    this.scanTimeout = const Duration(seconds: 10),
  }) {
    _subscriptions.addAll([
      _connection.connectionState.listen(_onConnectionState),
      _connection.batteryLevel.listen((v) => _update(() => _batteryPercent = v)),
      _connection.charging.listen((v) => _update(() => _isCharging = v)),
      _connection.status.listen((v) => _update(() => _status = v)),
    ]);
  }

  final BraceletConnection _connection;
  final Duration scanTimeout;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  StreamSubscription<List<BraceletScanResult>>? _scan;

  bool get isSupported => _connection.isSupported;

  BraceletConnectionState _connectionState =
      BraceletConnectionState.disconnected;
  BraceletConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == BraceletConnectionState.connected;

  String? _deviceName;

  /// The bracelet connected or being connected to.
  String? get deviceName => _deviceName;

  int? _batteryPercent;
  int? get batteryPercent => _batteryPercent;

  bool? _isCharging;
  bool? get isCharging => _isCharging;

  BraceletStatus? _status;
  Duration? get uptime => _status?.uptime;
  ResetReason? get resetReason => _status?.resetReason;

  BraceletDeviceInfo? _deviceInfo;
  String? get manufacturer => _deviceInfo?.manufacturer;
  String? get model => _deviceInfo?.model;

  List<BraceletScanResult> _scanResults = const [];
  List<BraceletScanResult> get scanResults => _scanResults;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  bool _hasScanned = false;

  /// Whether the last scan has finished, so an empty [scanResults] means
  /// nothing was found.
  bool get hasScanned => _hasScanned;

  BraceletError? _error;

  /// What went wrong with the last action, or why the link dropped. Cleared
  /// by the next action.
  BraceletError? get error => _error;

  bool _disconnectRequested = false;

  Future<void> startScan() async {
    if (!isSupported || _isScanning || isConnected) return;
    await _scan?.cancel();
    _update(() {
      _isScanning = true;
      _hasScanned = false;
      _scanResults = const [];
      _error = null;
    });
    final done = Completer<void>();
    _scan = _connection.scan(timeout: scanTimeout).listen(
          (results) => _update(() => _scanResults = results),
          onError: (Object e) => _update(() => _error = _errorOf(e, BraceletError.scanFailed)),
          onDone: done.complete,
        );
    await done.future;
    _scan = null;
    _update(() {
      _isScanning = false;
      _hasScanned = true;
    });
  }

  Future<void> stopScan() async {
    if (_isScanning) await _connection.stopScan();
  }

  Future<void> connect(BraceletScanResult bracelet) async {
    if (!isSupported || _connectionState != BraceletConnectionState.disconnected) {
      return;
    }
    await stopScan();
    _update(() {
      _deviceName = bracelet.name;
      _error = null;
      _connectionState = BraceletConnectionState.connecting;
    });
    try {
      final info = await _connection.connect(bracelet.id);
      _update(() => _deviceInfo = info);
    } catch (e) {
      _update(() {
        _error = _errorOf(e, BraceletError.connectionFailed);
        _clearDevice();
        _connectionState = BraceletConnectionState.disconnected;
      });
    }
  }

  Future<void> disconnect() async {
    _disconnectRequested = true;
    _update(() => _error = null);
    await _connection.disconnect();
  }

  /// Switches the bracelet off. It stays off until its reset button is
  /// pressed or it is plugged in.
  Future<void> shutdown() async {
    _disconnectRequested = true;
    _update(() => _error = null);
    await _connection.shutdown();
  }

  void _onConnectionState(BraceletConnectionState state) {
    _update(() {
      if (state == BraceletConnectionState.disconnected &&
          _connectionState == BraceletConnectionState.connected) {
        if (!_disconnectRequested) _error = BraceletError.connectionLost;
        _clearDevice();
      }
      if (state != BraceletConnectionState.connected) {
        _disconnectRequested = false;
      }
      _connectionState = state;
    });
  }

  void _clearDevice() {
    _deviceName = null;
    _deviceInfo = null;
    _batteryPercent = null;
    _isCharging = null;
    _status = null;
    _scanResults = const [];
    _hasScanned = false;
  }

  static BraceletError _errorOf(Object e, BraceletError fallback) =>
      e is BraceletException ? e.error : fallback;

  bool _disposed = false;

  void _update(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_scan?.cancel());
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
