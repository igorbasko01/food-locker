import 'package:food_locker/features/weight/data/weight.dart';

/// One calendar week's weight change, as the Home heatmap reads it.
///
/// Intra-week only: [delta] is the week's last weigh-in minus its first, so
/// nothing carries across a week boundary and every week stands on its own. A
/// week under [minEntries] weigh-ins reports no [delta] at all.
class WeeklyWeightChange {
  const WeeklyWeightChange({required this.weekStart, this.delta, this.unit});

  /// Weigh-ins a week needs before it reports a [delta].
  static const int minEntries = 4;

  /// The Sunday opening the week, at local midnight.
  final DateTime weekStart;

  /// Last weigh-in of the week minus its first, or null under [minEntries].
  final double? delta;

  /// The unit [delta] is expressed in; null exactly when [delta] is.
  final WeightUnit? unit;

  bool get hasData => delta != null;

  /// Whether the week ended heavier. A flat week counts as not gained.
  bool get isGain => (delta ?? 0) > 0;

  /// Magnitude bucket, 1 (faintest) to 4 (strongest), or null without a
  /// [delta]. The pound bounds are the kilogram ones doubled.
  int? get level {
    final magnitude = delta?.abs();
    if (magnitude == null) return null;
    final scale = unit == WeightUnit.pounds ? 2.0 : 1.0;
    if (magnitude < 0.25 * scale) return 1;
    if (magnitude < 0.5 * scale) return 2;
    if (magnitude < 1.0 * scale) return 3;
    return 4;
  }

  @override
  bool operator ==(Object other) =>
      other is WeeklyWeightChange &&
      other.weekStart == weekStart &&
      other.delta == delta &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(weekStart, delta, unit);

  @override
  String toString() =>
      'WeeklyWeightChange(weekStart: $weekStart, delta: $delta, unit: $unit)';
}
