import 'package:flutter/material.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';
import 'package:food_locker/ui/widgets/weekly_change_color.dart';

/// A year of weekly weight change as a grid of coloured cells.
///
/// Fills row by row, oldest top-left to newest bottom-right, so the last cell
/// is the week in progress. Unlabelled and non-interactive by design.
class WeeklyChangeHeatmap extends StatelessWidget {
  const WeeklyChangeHeatmap({super.key, required this.weeks});

  static const int rows = 4;
  static const int columns = 13;

  /// The weeks to draw, oldest first. Cells past the end of the list are drawn
  /// as no-data.
  final List<WeeklyWeightChange> weeks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var column = 0; column < columns; column++)
                Expanded(child: _Cell(color: _colorAt(row * columns + column))),
            ],
          ),
      ],
    );
  }

  Color _colorAt(int index) => index < weeks.length
      ? weeklyChangeColor(weeks[index])
      : weeklyChangeNoDataColor;
}

class _Cell extends StatelessWidget {
  const _Cell({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
