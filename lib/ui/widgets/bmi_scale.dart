import 'package:flutter/material.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/weight/data/bmi.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/ui/widgets/bmi_band_style.dart';

/// The current BMI on the four WHO bands, as a marker over a bar whose
/// segments are sized in proportion to the ranges they cover.
///
/// Given a [heightCm], each cut-off is also printed above the bar as the weight
/// it falls at for that height, in [system].
class BmiScale extends StatelessWidget {
  const BmiScale({
    super.key,
    required this.bmi,
    this.heightCm,
    this.system = MeasurementSystem.metric,
  });

  final double bmi;
  final double? heightCm;
  final MeasurementSystem system;

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

  /// The row the marker takes up: the drop-down glyph fills only the middle
  /// of its icon box, so the box overhangs this above and below.
  static const double _markerRowHeight = 14.0;

  /// The box each boundary figure is centred in, wide enough for `18.5`.
  static const double _tickWidth = 36.0;

  /// The same box for a boundary weight, wide enough for `132.3 lbs`.
  static const double _weightTickWidth = 64.0;

  static const Key barKey = Key('bmi-scale-bar');
  static const Key readingLineKey = Key('bmi-scale-reading-line');

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
              height: _markerRowHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: (_markerRowHeight - _markerSize) / 2,
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
          if (heightCm case final heightCm?)
            _ticks(
              theme,
              width: _weightTickWidth,
              label: (bmi) => Weight(
                kilogramsAtBmi(bmi: bmi, heightCm: heightCm),
                MeasurementSystem.metric,
              ).stringify(system, decimals: 1),
            ),
          ClipRRect(
            key: barKey,
            borderRadius: BorderRadius.circular(6),
            child: CustomPaint(
              key: readingLineKey,
              foregroundPainter: _ReadingLinePainter(markerFraction(bmi)),
              child: Row(children: BmiBand.all.map(_segment).toList()),
            ),
          ),
          _ticks(theme, width: _tickWidth, label: _boundaryLabel),
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

  /// A [label] for the cut-off at each seam in the bar, read off the bands
  /// themselves so the figures cannot drift out of step with the segments.
  Widget _ticks(
    ThemeData theme, {
    required double width,
    required String Function(double bmi) label,
  }) {
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
                  width,
                ),
                child: SizedBox(
                  width: width,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label(band.from), maxLines: 1, style: style),
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

/// A dashed line down the bar at [fraction] of its width, where the marker
/// points. The dashes alternate dark and light so the line shows on every band.
class _ReadingLinePainter extends CustomPainter {
  const _ReadingLinePainter(this.fraction);

  final double fraction;

  static const double _dash = 3.0;
  static const double _width = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final x = (fraction * size.width).clamp(
      _width / 2,
      size.width - _width / 2,
    );
    final dark = Paint()
      ..color = const Color(0xFF212121)
      ..strokeWidth = _width;
    final light = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = _width;

    var dashIndex = 0;
    for (var y = 0.0; y < size.height; y += _dash, dashIndex++) {
      final end = y + _dash > size.height ? size.height : y + _dash;
      canvas.drawLine(
        Offset(x, y),
        Offset(x, end),
        dashIndex.isEven ? dark : light,
      );
    }
  }

  @override
  bool shouldRepaint(_ReadingLinePainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}
