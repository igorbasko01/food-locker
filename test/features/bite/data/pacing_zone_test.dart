import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/pacing_zone.dart';

/// The pure zone computation. Boundaries are half-open `[b1, b2)`, so a gap
/// exactly on a boundary reads as the later (less costly) zone — matching the
/// storage windows.
void main() {
  const b1 = Duration(seconds: 15);
  const b2 = Duration(seconds: 30);

  PacingZone zoneAt(Duration elapsed) =>
      PacingZone.forElapsed(elapsed, b1: b1, b2: b2);

  test('zero elapsed is too soon', () {
    expect(zoneAt(Duration.zero), PacingZone.tooSoon);
  });

  test('just under b1 is too soon', () {
    expect(zoneAt(const Duration(seconds: 14, milliseconds: 999)),
        PacingZone.tooSoon);
  });

  test('exactly b1 crosses into hold on', () {
    expect(zoneAt(b1), PacingZone.holdOn);
  });

  test('between b1 and b2 is hold on', () {
    expect(zoneAt(const Duration(seconds: 22)), PacingZone.holdOn);
  });

  test('just under b2 is still hold on', () {
    expect(zoneAt(const Duration(seconds: 29, milliseconds: 999)),
        PacingZone.holdOn);
  });

  test('exactly b2 crosses into the clear', () {
    expect(zoneAt(b2), PacingZone.inTheClear);
  });

  test('well past b2 is in the clear', () {
    expect(zoneAt(const Duration(minutes: 5)), PacingZone.inTheClear);
  });
}
