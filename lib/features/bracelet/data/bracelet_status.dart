/// Why the bracelet last restarted, as its firmware reports it.
enum ResetReason {
  powerOn(0, 'Power on'),
  resetPin(1, 'Reset button'),
  watchdog(2, 'Watchdog'),
  software(3, 'Software reset'),
  lockup(4, 'CPU fault'),
  usbWake(5, 'USB wake'),
  other(255, 'Other');

  const ResetReason(this.code, this.label);

  final int code;
  final String label;

  static ResetReason fromCode(int code) =>
      values.firstWhere((r) => r.code == code, orElse: () => other);
}

/// One reading of the bracelet's Status characteristic.
class BraceletStatus {
  const BraceletStatus({required this.uptime, required this.resetReason});

  final Duration uptime;
  final ResetReason resetReason;

  @override
  bool operator ==(Object other) =>
      other is BraceletStatus &&
      other.uptime == uptime &&
      other.resetReason == resetReason;

  @override
  int get hashCode => Object.hash(uptime, resetReason);
}

/// Parses the 5-byte Status payload: a little-endian uint32 of uptime seconds,
/// then a uint8 reset reason. Returns null for any other length.
BraceletStatus? parseBraceletStatus(List<int> bytes) {
  if (bytes.length != 5) return null;
  final seconds = (bytes[0] & 0xff) |
      (bytes[1] & 0xff) << 8 |
      (bytes[2] & 0xff) << 16 |
      (bytes[3] & 0xff) << 24;
  return BraceletStatus(
    uptime: Duration(seconds: seconds),
    resetReason: ResetReason.fromCode(bytes[4] & 0xff),
  );
}
