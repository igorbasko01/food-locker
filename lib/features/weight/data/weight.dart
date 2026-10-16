import 'package:food_locker/core/units.dart';

/// One day's weigh-in.
class WeightEntry {
  const WeightEntry({required this.date, required this.weight});

  final DateTime date;
  final Weight weight;
}

/// An amount of weight with no date: a weigh-in's reading, a mean, a low.
///
/// Built from and read as a figure in a [MeasurementSystem];
/// [MeasurementSystem.metric] is the one storage and backups use.
class Weight implements Comparable<Weight> {
  Weight(double value, MeasurementSystem system)
    : _kilograms = system.weightToKilograms(value);

  const Weight._(this._kilograms);

  final double _kilograms;

  /// The mean of [weights], or null when there are none.
  static Weight? mean(Iterable<Weight> weights) {
    if (weights.isEmpty) return null;
    final total = weights.fold(0.0, (sum, w) => sum + w._kilograms);
    return Weight._(total / weights.length);
  }

  /// How far this sits above [other]; negative when it is lighter.
  WeightChange diff(Weight other) =>
      WeightChange._(_kilograms - other._kilograms);

  /// The amount in [system]'s unit.
  double value(MeasurementSystem system) =>
      system.weightFromKilograms(_kilograms);

  /// `72.57 kg`, `160.00 lbs`; without [withSymbol], the bare number for a
  /// field or an axis that names the unit elsewhere.
  String stringify(
    MeasurementSystem system, {
    int decimals = 2,
    bool withSymbol = true,
  }) {
    final number = value(system).toStringAsFixed(decimals);
    return withSymbol ? '$number ${system.weightSymbol}' : number;
  }

  bool operator <(Weight other) => _kilograms < other._kilograms;

  @override
  int compareTo(Weight other) => _kilograms.compareTo(other._kilograms);

  @override
  bool operator ==(Object other) =>
      other is Weight && other._kilograms == _kilograms;

  @override
  int get hashCode => _kilograms.hashCode;

  @override
  String toString() => 'Weight($_kilograms kg)';
}

/// A signed difference between two [Weight]s: a day's change, a week's, a
/// trend.
class WeightChange {
  WeightChange(double value, MeasurementSystem system)
    : _kilograms = system.weightToKilograms(value);

  const WeightChange._(this._kilograms);

  final double _kilograms;

  /// This change scaled, as a weekly trend projected over a month.
  WeightChange operator *(num factor) => WeightChange._(_kilograms * factor);

  /// The change in [system]'s unit, rounded to what [stringify] prints with the
  /// same [decimals], so a sign, colour or arrow taken from it agrees with the
  /// digits: `-0.004` kg at two places is zero.
  double value(MeasurementSystem system, {int decimals = 2}) =>
      _roundTo(system.weightFromKilograms(_kilograms), decimals);

  /// `+0.05 kg`, `-1.54 lbs`, and an unsigned `0.00 kg` once it rounds to zero.
  String stringify(MeasurementSystem system, {int decimals = 2}) {
    final rounded = value(system, decimals: decimals);
    final magnitude =
        '${rounded.abs().toStringAsFixed(decimals)} ${system.weightSymbol}';
    if (rounded > 0) return '+$magnitude';
    if (rounded < 0) return '-$magnitude';
    return magnitude;
  }

  @override
  bool operator ==(Object other) =>
      other is WeightChange && other._kilograms == _kilograms;

  @override
  int get hashCode => _kilograms.hashCode;

  @override
  String toString() => 'WeightChange($_kilograms kg)';
}

/// Parsed back from [double.toStringAsFixed] rather than computed as
/// `(value * 100).round() / 100`, whose binary error can round the other way
/// from the printed text.
double _roundTo(double value, int decimals) =>
    double.parse(value.toStringAsFixed(decimals));
