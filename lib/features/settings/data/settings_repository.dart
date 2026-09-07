import 'package:food_locker/features/weight/data/weight.dart';

/// Persistence for the preferences that sit outside the two data stores — the
/// ones that are a current answer rather than a dated series.
///
/// Reads are synchronous so a widget can render a preference without an await;
/// implementations hold the value in memory and write through on change.
abstract class SettingsRepository {
  /// The unit weights are shown and typed in. Storage stays kilograms whatever
  /// this says — it is a display-and-input concern, converted at the boundary.
  WeightUnit get weightUnit;

  Future<void> setWeightUnit(WeightUnit unit);
}
