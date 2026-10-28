import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bracelet/data/bracelet_status.dart';

void main() {
  group('parseBraceletStatus', () {
    test('reads little-endian uptime seconds and the reset reason', () {
      // 4320 s = 0x000010E0, reset pin.
      expect(
        parseBraceletStatus([0xE0, 0x10, 0x00, 0x00, 1]),
        const BraceletStatus(
          uptime: Duration(seconds: 4320),
          resetReason: ResetReason.resetPin,
        ),
      );
    });

    test('reads the full uint32 range', () {
      final status = parseBraceletStatus([0xFF, 0xFF, 0xFF, 0xFF, 0])!;
      expect(status.uptime, const Duration(seconds: 0xFFFFFFFF));
      expect(status.resetReason, ResetReason.powerOn);
    });

    test('maps every documented reset code', () {
      for (final reason in ResetReason.values) {
        expect(
          parseBraceletStatus([0, 0, 0, 0, reason.code])!.resetReason,
          reason,
        );
      }
    });

    test('treats an undocumented reset code as other', () {
      expect(
        parseBraceletStatus([0, 0, 0, 0, 42])!.resetReason,
        ResetReason.other,
      );
    });

    test('rejects a payload of the wrong length', () {
      expect(parseBraceletStatus([]), isNull);
      expect(parseBraceletStatus([1, 2, 3, 4]), isNull);
      expect(parseBraceletStatus([1, 2, 3, 4, 5, 6]), isNull);
    });
  });
}
