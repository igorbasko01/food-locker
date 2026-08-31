import 'package:flutter/material.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';

/// The heatmap's colour for a week that reported no change.
const Color weeklyChangeNoDataColor = Color(0xFFEEEEEE);

/// The single point where a week's change becomes a heatmap colour.
///
/// Loss is green and gain is red, matching the app's loss-oriented framing; a
/// later "goal direction" setting swaps the two ramps here, leaving the grid
/// untouched. The shades are fixed rather than theme-derived, so a cell keeps
/// its meaning whatever the palette does.
Color weeklyChangeColor(WeeklyWeightChange week) {
  final level = week.level;
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
