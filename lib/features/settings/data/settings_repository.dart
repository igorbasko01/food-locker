import 'package:food_locker/core/units.dart';

/// Persistence for the single-value preferences that sit outside the two data
/// stores — the ones that are a current answer rather than a dated series.
///
/// Reads are synchronous so a page can render a preference without an await;
/// implementations keep the values in memory and write through on change.
abstract class SettingsRepository {
  /// The stored height in centimetres, or null when it was never answered.
  /// Absence is a real state: nothing may stand a default body in for it.
  double? get heightCm;

  /// Null clears the height back to unanswered.
  Future<void> setHeightCm(double? centimetres);

  /// The system heights are shown and entered in. Metric until chosen.
  MeasurementSystem get measurementSystem;

  Future<void> setMeasurementSystem(MeasurementSystem system);
}
