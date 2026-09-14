import 'package:flutter/material.dart';
import 'package:food_locker/features/weight/data/bmi.dart';

/// Fixed visual styling for each [BmiCategory], the way PacingZoneStyle does
/// it for the bite zones: [fillColor] carries the band on the scale, and
/// [onFillColor] is the colour its [label] is drawn in, picked per band for
/// contrast against the fill. Fixed constants rather than theme-derived, so the
/// bands read the same in either theme.
class BmiBandStyle {
  const BmiBandStyle({
    required this.fillColor,
    required this.onFillColor,
    required this.label,
    required this.shortLabel,
  });

  final Color fillColor;
  final Color onFillColor;
  final String label;

  /// What fits inside a band's own segment of the scale, where the narrowest
  /// is a seventh of the bar.
  final String shortLabel;

  static BmiBandStyle of(BmiCategory category) {
    switch (category) {
      case BmiCategory.underweight:
        return const BmiBandStyle(
          fillColor: Color(0xFF1565C0), // blue
          onFillColor: Color(0xFFFFFFFF),
          label: 'Underweight',
          shortLabel: 'Under',
        );
      case BmiCategory.healthy:
        return const BmiBandStyle(
          fillColor: Color(0xFF2E7D32), // green
          onFillColor: Color(0xFFFFFFFF),
          label: 'Healthy',
          shortLabel: 'Healthy',
        );
      case BmiCategory.overweight:
        return const BmiBandStyle(
          fillColor: Color(0xFFF9A825), // amber
          onFillColor: Color(0xFF212121), // dark — white is illegible on amber
          label: 'Overweight',
          shortLabel: 'Over',
        );
      case BmiCategory.obese:
        return const BmiBandStyle(
          fillColor: Color(0xFFD32F2F), // red
          onFillColor: Color(0xFFFFFFFF),
          label: 'Obese',
          shortLabel: 'Obese',
        );
    }
  }
}
