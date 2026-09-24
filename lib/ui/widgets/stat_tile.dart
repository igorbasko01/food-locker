import 'package:flutter/material.dart';

/// A compact labelled statistic: a caption, a big value, and an optional
/// sub-line beneath it. Sized to sit in a row of equal-width tiles, so the
/// analytics screen's averages and max read as one band.
///
/// The sub-line's space is always reserved (an empty line when [subLabel] is
/// null), so tiles in a row keep the same height whether or not they carry one.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.subLabel,
    this.valueColor,
    this.icon,
  });

  /// The caption above the value, e.g. `30-day average`.
  final String label;

  /// The headline figure, already formatted for display.
  final String value;

  /// An optional line beneath the value, e.g. the date of a max day.
  final String? subLabel;

  /// Overrides the value's default `colorScheme.primary`, for tiles whose
  /// figure carries a direction of its own.
  final Color? valueColor;

  /// An optional glyph beside the value, drawn in the same colour.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final figureColor = valueColor ?? theme.colorScheme.primary;
    // One spoken node per tile — the caption, value, and any sub-line read as a
    // single phrase rather than three fragments (the reserved empty sub-line
    // included).
    final semanticsLabel = subLabel == null
        ? '$label: $value'
        : '$label: $value, $subLabel';
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Scaled down rather than wrapped, so a long signed reading like
              // `-0.45 kg/wk` stays on one line and tiles keep their heights.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: figureColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: figureColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subLabel ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
