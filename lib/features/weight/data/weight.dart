import 'package:food_locker/core/units.dart';
import 'package:hive_ce/hive.dart';

part 'weight.g.dart';

@HiveType(typeId: 3)
enum WeightUnit {
  @HiveField(0)
  kilograms,
  @HiveField(1)
  pounds,
}

/// One day's weigh-in, as the store holds it.
@HiveType(typeId: 4)
class WeightEntry {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double kilograms;

  /// Legacy provenance: always written as kilograms and never read.
  @HiveField(2)
  final WeightUnit unit;

  WeightEntry({
    required this.date,
    required this.kilograms,
    this.unit = WeightUnit.kilograms,
  });

  Weight get weight => Weight.kilograms(kilograms);
}

/// An amount of weight with no date: a weigh-in's reading, a mean, a low.
///
/// Held in kilograms; [value] and [stringify] read it in a
/// [MeasurementSystem], so callers never convert it themselves.
class Weight implements Comparable<Weight> {
  const Weight.kilograms(this.kilograms);

  /// A figure typed or shown in [system].
  Weight.inSystem(double value, MeasurementSystem system)
    : kilograms = system.weightToKilograms(value);

  final double kilograms;

  /// The mean of [weights], or null when there are none.
  static Weight? mean(Iterable<Weight> weights) {
    if (weights.isEmpty) return null;
    final total = weights.fold(0.0, (sum, w) => sum + w.kilograms);
    return Weight.kilograms(total / weights.length);
  }

  /// How far this sits above [other]; negative when it is lighter.
  WeightChange diff(Weight other) =>
      WeightChange.kilograms(kilograms - other.kilograms);

  /// The amount in [system]'s unit.
  double value(MeasurementSystem system) =>
      system.weightFromKilograms(kilograms);

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

  bool operator <(Weight other) => kilograms < other.kilograms;

  @override
  int compareTo(Weight other) => kilograms.compareTo(other.kilograms);

  @override
  bool operator ==(Object other) =>
      other is Weight && other.kilograms == kilograms;

  @override
  int get hashCode => kilograms.hashCode;

  @override
  String toString() => 'Weight($kilograms kg)';
}

/// A signed difference between two [Weight]s: a day's change, a week's, a
/// trend.
class WeightChange {
  const WeightChange.kilograms(this.kilograms);

  final double kilograms;

  /// This change scaled, as a weekly trend projected over a month.
  WeightChange operator *(num factor) =>
      WeightChange.kilograms(kilograms * factor);

  /// The change in [system]'s unit, rounded to what [stringify] prints with the
  /// same [decimals], so a sign, colour or arrow taken from it agrees with the
  /// digits: `-0.004` kg at two places is zero.
  double value(MeasurementSystem system, {int decimals = 2}) =>
      _roundTo(system.weightFromKilograms(kilograms), decimals);

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
      other is WeightChange && other.kilograms == kilograms;

  @override
  int get hashCode => kilograms.hashCode;

  @override
  String toString() => 'WeightChange($kilograms kg)';
}

/// Parsed back from [double.toStringAsFixed] rather than computed as
/// `(value * 100).round() / 100`, whose binary error can round the other way
/// from the printed text.
double _roundTo(double value, int decimals) =>
    double.parse(value.toStringAsFixed(decimals));
