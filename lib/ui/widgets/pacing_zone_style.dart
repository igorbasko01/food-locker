import 'package:flutter/material.dart';
import 'package:food_locker/features/bite/data/pacing_zone.dart';

/// Fixed visual styling for each [PacingZone].
///
/// The tap button is the pacing surface: its fill takes [fillColor] (the red /
/// amber / green zone semantics) and it names the zone with [label].
/// [onFillColor] is the icon/text colour, picked per zone for contrast against
/// the fill — white on the dark red and green, near-black on the light amber.
/// The colours are fixed constants rather than theme-derived, so the zone
/// semantics read the same regardless of the app's palette.
class PacingZoneStyle {
  const PacingZoneStyle({
    required this.fillColor,
    required this.onFillColor,
    required this.label,
  });

  final Color fillColor;
  final Color onFillColor;
  final String label;

  static PacingZoneStyle of(PacingZone zone) {
    switch (zone) {
      case PacingZone.tooSoon:
        return const PacingZoneStyle(
          fillColor: Color(0xFFD32F2F), // red
          onFillColor: Color(0xFFFFFFFF),
          label: 'Too soon',
        );
      case PacingZone.holdOn:
        return const PacingZoneStyle(
          fillColor: Color(0xFFF9A825), // amber
          onFillColor: Color(0xFF212121), // dark — white is illegible on amber
          label: 'Hold on',
        );
      case PacingZone.inTheClear:
        return const PacingZoneStyle(
          fillColor: Color(0xFF2E7D32), // green
          onFillColor: Color(0xFFFFFFFF),
          label: 'Clear',
        );
    }
  }
}
