import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/pacing_zone.dart';
import 'package:food_locker/ui/widgets/pacing_zone_style.dart';

/// The button carries the zone as colour + label, so the styling constants
/// must stay distinct per zone and legible against their own fill.
void main() {
  test('each zone maps to a distinct label and fill', () {
    final styles = {
      for (final zone in PacingZone.values) zone: PacingZoneStyle.of(zone),
    };

    final labels = styles.values.map((s) => s.label).toSet();
    final fills = styles.values.map((s) => s.fillColor).toSet();
    expect(labels.length, PacingZone.values.length, reason: 'labels are unique');
    expect(fills.length, PacingZone.values.length, reason: 'fills are unique');

    expect(styles[PacingZone.tooSoon]!.label, 'Too soon');
    expect(styles[PacingZone.holdOn]!.label, 'Hold on');
    expect(styles[PacingZone.inTheClear]!.label, 'Clear');
  });

  test('on-fill colour keeps legible contrast against every fill', () {
    // The amber fill is the tricky case: white would be illegible there, so its
    // on-colour must be dark. Assert a real WCAG contrast ratio for every zone —
    // >3:1 is the AA floor for the large button label/icon.
    for (final zone in PacingZone.values) {
      final style = PacingZoneStyle.of(zone);
      final ratio = _contrastRatio(style.onFillColor, style.fillColor);
      expect(ratio, greaterThan(3.0),
          reason: '$zone on-colour must contrast with its fill (got $ratio)');
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
