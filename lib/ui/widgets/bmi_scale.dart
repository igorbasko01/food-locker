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
  ///
  /// The top end is cut close: past the mid-thirties the reading is bad by any
  /// measure, and every point given back there widens the healthy band, where a
  /// reader actually wants to see where they sit. The bar stays linear, so
  /// equal widths mean equal BMI points across all four bands.
  static const double domainFrom = 15.0;
  static const double domainTo = 35.0;

  static const double _barHeight = 26.0;
  static const double _markerSize = 28.0;

  /// The box each boundary figure is centred in, wide enough for `18.5`.
  static const double _tickWidth = 36.0;

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
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: _markerSize,
              child: Stack(
                children: [
                  Positioned(
                    left: _centredAt(
                      markerFraction(bmi),
                      constraints.maxWidth,
                      _markerSize,
                    ),
                    child: Icon(
                      Icons.arrow_drop_down,
                      size: _markerSize,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRRect(
            key: barKey,
            borderRadius: BorderRadius.circular(6),
            child: Row(children: BmiBand.all.map(_segment).toList()),
          ),
          _boundaries(theme),
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

  /// The left edge of a box [itemWidth] wide centred on [fraction] of a bar
  /// [width] wide, kept inside the bar at both ends. Aligning the box itself
  /// would sweep its centre over `[itemWidth / 2, width - itemWidth / 2]` and
  /// drift what it points at by up to half its width.
  static double _centredAt(double fraction, double width, double itemWidth) {
    final left = fraction * width - itemWidth / 2;
    final furthest = width - itemWidth;
    if (left < 0) return 0.0;
    return left > furthest ? furthest : left;
  }

  /// The cut-off under each seam in the bar, read off the bands themselves so
  /// the figures cannot drift out of step with the segments above them.
  Widget _boundaries(ThemeData theme) {
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: 18,
        child: Stack(
          children: [
            for (final band in BmiBand.all.skip(1))
              Positioned(
                left: _centredAt(
                  markerFraction(band.from),
                  constraints.maxWidth,
                  _tickWidth,
                ),
                child: SizedBox(
                  width: _tickWidth,
                  child: Text(
                    _boundaryLabel(band.from),
                    textAlign: TextAlign.center,
                    style: style,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _boundaryLabel(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

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
