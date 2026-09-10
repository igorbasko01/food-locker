import 'package:flutter/material.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';
import 'package:food_locker/ui/widgets/weekly_change_color.dart';
import 'package:food_locker/ui/widgets/weekly_change_summary.dart';

/// A year of weekly weight change as a grid of coloured cells.
///
/// Fills row by row, oldest top-left to newest bottom-right, so the last cell
/// is the week in progress. Holding a cell names the week it covers and the
/// weigh-ins its colour came from; dragging carries that readout from cell to
/// cell, and lifting ends it.
class WeeklyChangeHeatmap extends StatefulWidget {
  const WeeklyChangeHeatmap({super.key, required this.weeks});

  static const int rows = 4;
  static const int columns = 13;

  /// The weeks to draw, oldest first. Cells past the end of the list are drawn
  /// as no-data.
  final List<WeeklyWeightChange> weeks;

  @override
  State<WeeklyChangeHeatmap> createState() => _WeeklyChangeHeatmapState();
}

class _WeeklyChangeHeatmapState extends State<WeeklyChangeHeatmap> {
  /// How far above the held cell's centre the readout sits. A cell is a few
  /// millimetres across, so anything less opens under the fingertip.
  static const double _readoutOffset = 36;

  OverlayEntry? _readout;
  int? _held;
  Offset _target = Offset.zero;

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Each cell is a square of one column's width: the row's Expanded sets
        // the width and the AspectRatio inside follows it.
        final cellSize = constraints.maxWidth / WeeklyChangeHeatmap.columns;

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _holdAt(event.position, cellSize),
          onPointerMove: (event) => _holdAt(event.position, cellSize),
          onPointerUp: (_) => _hide(),
          onPointerCancel: (_) => _hide(),
          child: Column(
            children: [
              for (var row = 0; row < WeeklyChangeHeatmap.rows; row++)
                Row(
                  children: [
                    for (
                      var column = 0;
                      column < WeeklyChangeHeatmap.columns;
                      column++
                    )
                      Expanded(child: _Cell(week: _weekAt(_index(row, column)))),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  int _index(int row, int column) => row * WeeklyChangeHeatmap.columns + column;

  WeeklyWeightChange? _weekAt(int index) =>
      index < widget.weeks.length ? widget.weeks[index] : null;

  /// Moves the readout to whichever cell [globalPosition] falls in, or hides it
  /// once the finger leaves the grid.
  void _holdAt(Offset globalPosition, double cellSize) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final local = box.globalToLocal(globalPosition);
    final column = local.dx ~/ cellSize;
    final row = local.dy ~/ cellSize;
    if (local.dx < 0 ||
        local.dy < 0 ||
        column >= WeeklyChangeHeatmap.columns ||
        row >= WeeklyChangeHeatmap.rows) {
      _hide();
      return;
    }

    // Re-read the centre every move, so the readout stays on its cell even
    // while the page scrolls under the finger.
    _held = _index(row, column);
    _target = box.localToGlobal(
      Offset((column + 0.5) * cellSize, (row + 0.5) * cellSize),
    );

    if (_readout == null) {
      _readout = OverlayEntry(builder: _buildReadout);
      Overlay.of(context, debugRequiredFor: widget).insert(_readout!);
    } else {
      _readout!.markNeedsBuild();
    }
  }

  Widget _buildReadout(BuildContext context) {
    final held = _held;
    if (held == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomSingleChildLayout(
          delegate: _AboveCell(target: _target, verticalOffset: _readoutOffset),
          child: _Readout(lines: weeklyChangeSummary(_weekAt(held))),
        ),
      ),
    );
  }

  void _hide() {
    _readout?.remove();
    _readout = null;
    _held = null;
  }
}

/// Places the readout above [target], dropping below it when the cell sits too
/// near the top of the screen to fit, and keeping clear of the screen edges.
class _AboveCell extends SingleChildLayoutDelegate {
  const _AboveCell({required this.target, required this.verticalOffset});

  static const double _margin = 8;

  final Offset target;
  final double verticalOffset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(constraints.maxWidth - 2 * _margin, constraints.maxHeight),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final above = target.dy - verticalOffset - childSize.height;
    final furthestDown = size.height - childSize.height;
    final y = above >= _margin
        ? above
        : (furthestDown <= _margin
              ? _margin
              : (target.dy + verticalOffset).clamp(_margin, furthestDown));

    final furthestLeft = size.width - childSize.width - _margin;
    final x = furthestLeft <= _margin
        ? (size.width - childSize.width) / 2
        : (target.dx - childSize.width / 2).clamp(_margin, furthestLeft);

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_AboveCell oldDelegate) => target != oldDelegate.target;
}

class _Readout extends StatelessWidget {
  const _Readout({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          lines.join('\n'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onInverseSurface,
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.week});

  /// The week this cell draws, or null past the end of the grid.
  final WeeklyWeightChange? week;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: AspectRatio(
        aspectRatio: 1,
        child: Semantics(
          label: weeklyChangeSummary(week).join('. '),
          excludeSemantics: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: week == null
                  ? weeklyChangeNoDataColor
                  : weeklyChangeColor(week!),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
