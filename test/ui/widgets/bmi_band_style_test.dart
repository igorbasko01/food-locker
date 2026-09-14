import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/bmi.dart';
import 'package:food_locker/ui/widgets/bmi_band_style.dart';

/// The scale carries each band as colour + label, so the styling constants must
/// stay distinct per band and legible against their own fill.
void main() {
  test('each band maps to a distinct label and fill', () {
    final styles = {
      for (final category in BmiCategory.values)
        category: BmiBandStyle.of(category),
    };

    final labels = styles.values.map((s) => s.label).toSet();
    final fills = styles.values.map((s) => s.fillColor).toSet();
    expect(labels.length, BmiCategory.values.length, reason: 'labels are unique');
    expect(fills.length, BmiCategory.values.length, reason: 'fills are unique');

    expect(styles[BmiCategory.underweight]!.label, 'Underweight');
    expect(styles[BmiCategory.healthy]!.label, 'Healthy');
    expect(styles[BmiCategory.overweight]!.label, 'Overweight');
    expect(styles[BmiCategory.obese]!.label, 'Obese');
  });

  test('on-fill colour keeps legible contrast against every fill', () {
    // The amber fill is the tricky case: white would be illegible there, so its
    // on-colour must be dark. >3:1 is the AA floor for this label size.
    for (final category in BmiCategory.values) {
      final style = BmiBandStyle.of(category);
      final ratio = _contrastRatio(style.onFillColor, style.fillColor);
      expect(ratio, greaterThan(3.0),
          reason: '$category on-colour must contrast with its fill (got $ratio)');
    }
  });
}

/// WCAG contrast ratio between two opaque colours.
double _contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
