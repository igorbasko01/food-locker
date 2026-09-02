import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';
import 'package:food_locker/ui/widgets/weekly_change_color.dart';
import 'package:food_locker/ui/widgets/weekly_change_summary.dart';

/// A year of weekly weight change as a grid of coloured cells.
///
/// Fills row by row, oldest top-left to newest bottom-right, so the last cell
/// is the week in progress. Holding a cell names the week it covers and the
/// weigh-ins its colour came from.
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
                Expanded(child: _Cell(week: _weekAt(row * columns + column))),
            ],
          ),
      ],
    );
  }

  WeeklyWeightChange? _weekAt(int index) =>
      index < weeks.length ? weeks[index] : null;
}

class _Cell extends StatefulWidget {
  const _Cell({required this.week});

  /// The week this cell draws, or null past the end of the grid.
  final WeeklyWeightChange? week;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
  final GlobalKey<TooltipState> _tooltip = GlobalKey<TooltipState>();
  Offset? _pressOrigin;

  void _showTooltip(PointerDownEvent event) {
    _pressOrigin = event.position;
    _tooltip.currentState?.ensureTooltipVisible();
  }

  /// A finger that travels is scrolling Home, not reading a cell, and the
  /// overlay stays where it opened rather than following the page.
  void _dismissIfDragged(PointerMoveEvent event) {
    final origin = _pressOrigin;
    if (origin != null && (event.position - origin).distance > kTouchSlop) {
      _dismissTooltip();
    }
  }

  void _dismissTooltip([PointerEvent? event]) {
    _pressOrigin = null;
    Tooltip.dismissAllToolTips();
  }

  @override
  Widget build(BuildContext context) {
    final week = widget.week;
    final summary = weeklyChangeSummary(week);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: AspectRatio(
        aspectRatio: 1,
        child: Semantics(
          label: summary.join('. '),
          excludeSemantics: true,
          child: Tooltip(
            key: _tooltip,
            message: summary.join('\n'),
            // Shown and hidden below, so the week reads for exactly as long
            // as the finger is down.
            triggerMode: TooltipTriggerMode.manual,
            enableTapToDismiss: false,
            excludeFromSemantics: true,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _showTooltip,
              onPointerMove: _dismissIfDragged,
              onPointerUp: _dismissTooltip,
              onPointerCancel: _dismissTooltip,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: week == null
                      ? weeklyChangeNoDataColor
                      : weeklyChangeColor(week),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
