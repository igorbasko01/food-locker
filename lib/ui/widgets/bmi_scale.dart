import 'package:flutter/material.dart';
import 'package:food_locker/features/weight/data/bmi.dart';
import 'package:food_locker/ui/widgets/bmi_band_style.dart';

/// The current BMI on the four WHO bands, as a marker over a bar whose
/// segments are sized in proportion to the ranges they cover.
class BmiScale extends StatelessWidget {
  const BmiScale({super.key, required this.bmi});

  final double bmi;

  /// The drawn domain. The obese band runs to infinity and the underweight one
  /// to zero, so both are cut off here — otherwise the bar has no right edge
  /// and the healthy band is a sliver. A BMI outside it pins the marker to the
  /// end while the caption still reads the true value.
  static const double domainFrom = 15.0;
  static const double domainTo = 40.0;

  static const double _barHeight = 26.0;

  static const Key barKey = Key('bmi-scale-bar');

  /// Where along the bar [bmi] sits, 0 at the left edge and 1 at the right.
  static double markerFraction(double bmi) {
    final fraction = (bmi - domainFrom) / (domainTo - domainFrom);
    if (fraction < 0) return 0.0;
    if (fraction > 1) return 1.0;
    return fraction;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Banded on the figure as printed, so the caption never contradicts itself:
    // a 24.97 rounds to 25.0, and 25.0 is overweight.
    final reading = double.parse(bmi.toStringAsFixed(1));
    final style = BmiBandStyle.of(bmiCategory(reading));
    final printed = reading.toStringAsFixed(1);

    return Semantics(
      label: 'BMI $printed, ${style.label.toLowerCase()} range',
      excludeSemantics: true,
      child: Column(
        // The Weight tab hands this an unbounded height.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$printed · ${style.label}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment(markerFraction(bmi) * 2 - 1, 0),
            child: Icon(
              Icons.arrow_drop_down,
              size: 28,
              color: theme.colorScheme.onSurface,
            ),
          ),
          ClipRRect(
            key: barKey,
            borderRadius: BorderRadius.circular(6),
            child: Row(children: BmiBand.all.map(_segment).toList()),
          ),
          const SizedBox(height: 6),
          Text(
            'BMI is a rough screening figure for adults. It ignores body '
            'composition, and does not apply to children or during pregnancy.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(BmiBand band) {
    final style = BmiBandStyle.of(band.category);
    final from = band.from < domainFrom ? domainFrom : band.from;
    final to = band.to > domainTo ? domainTo : band.to;

    return Expanded(
      // Tenths of a BMI point, so 18.5 divides a band without rounding it away.
      flex: ((to - from) * 10).round(),
      child: Container(
        height: _barHeight,
        alignment: Alignment.center,
        color: style.fillColor,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            style.shortLabel,
            maxLines: 1,
            style: TextStyle(
              color: style.onFillColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
