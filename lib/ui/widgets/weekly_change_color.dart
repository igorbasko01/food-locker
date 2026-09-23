import 'dart:math';

import 'package:flutter/material.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';

/// The heatmap's colour for a week that reported no change.
const Color weeklyChangeNoDataColor = Color(0xFFEEEEEE);

/// The magnitude the grid's darkest shade is measured against.
///
/// Mean-to-mean deltas are damped, so fixed kilogram buckets would leave a
/// typical year uniformly pale. The ramp is stretched to the weeks on screen
/// instead: proportionality survives — a week twice as big as another still
/// looks twice as strong — but a quiet year fills out its palette as readily
/// as a dramatic one.
///
/// Built from the whole grid, since no single week can say what is big for the
/// grid it sits in.
class WeeklyChangeScale {
  /// The 90th percentile of the grid's magnitudes, never below [floor].
  ///
  /// p90 rather than the maximum, so one flu week cannot compress every normal
  /// week into the faintest shade.
  factory WeeklyChangeScale.forWeeks(Iterable<WeeklyWeightChange> weeks) {
    final magnitudes = [
      for (final week in weeks)
        if (week.delta != null) week.delta!.abs(),
    ]..sort();
    if (magnitudes.isEmpty) return const WeeklyChangeScale._(floor);

    final rank = (0.9 * magnitudes.length).ceil() - 1;
    return WeeklyChangeScale._(max(magnitudes[rank], floor));
  }

  const WeeklyChangeScale._(this.reference);

  /// The smallest reference the grid will scale to, in kilograms, so a
  /// genuinely flat year looks flat instead of amplifying a few grams of noise
  /// into dark green.
  static const double floor = 0.4;

  final double reference;

  /// Magnitude bucket, 1 (faintest) to 4 (strongest), or null for a week with
  /// no delta.
  int? levelFor(WeeklyWeightChange week) {
    final magnitude = week.delta?.abs();
    if (magnitude == null) return null;
    if (magnitude < 0.25 * reference) return 1;
    if (magnitude < 0.50 * reference) return 2;
    if (magnitude < 0.75 * reference) return 3;
    return 4;
  }
}

/// The single point where a week's change becomes a heatmap colour.
///
/// Loss is green and gain is red, matching the app's loss-oriented framing; a
/// later "goal direction" setting swaps the two ramps here, leaving the grid
/// untouched. The shades are fixed rather than theme-derived, so a cell keeps
/// its meaning whatever the palette does.
Color weeklyChangeColor(WeeklyWeightChange week, WeeklyChangeScale scale) {
  final level = scale.levelFor(week);
  if (level == null) return weeklyChangeNoDataColor;
  return (week.isGain ? _gainRamp : _lossRamp)[level - 1];
}

const List<Color> _lossRamp = [
  Color(0xFFC8E6C9),
  Color(0xFF81C784),
  Color(0xFF43A047),
  Color(0xFF1B5E20),
];

const List<Color> _gainRamp = [
  Color(0xFFFFCDD2),
  Color(0xFFE57373),
  Color(0xFFE53935),
  Color(0xFFB71C1C),
];
