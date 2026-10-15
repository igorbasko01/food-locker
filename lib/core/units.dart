/// The system a figure is shown and typed in. Storage stays metric whatever
/// this says — it is a display-and-input concern, converted at the boundary.
enum MeasurementSystem { metric, imperial }

/// Exact by definition, and the only place the inch is spelled out.
const double centimetresPerInch = 2.54;

const int inchesPerFoot = 12;

double inchesToCentimetres(double inches) => inches * centimetresPerInch;

double centimetresToInches(double centimetres) =>
    centimetres / centimetresPerInch;

/// A length the way a height is said out loud: whole feet plus the inches left
/// over.
class FeetInches {
  final int feet;
  final double inches;

  const FeetInches(this.feet, this.inches);
}

FeetInches centimetresToFeetInches(double centimetres) {
  final totalInches = centimetresToInches(centimetres);
  final feet = totalInches ~/ inchesPerFoot;
  return FeetInches(feet, totalInches - feet * inchesPerFoot);
}

double feetInchesToCentimetres(int feet, double inches) =>
    inchesToCentimetres(feet * inchesPerFoot + inches);

/// [centimetres] as feet and inches rounded to [decimals] places, carrying a
/// rounded-up twelve into the next foot so no display or field ever reads
/// `5' 12"`.
FeetInches roundedFeetInches(double centimetres, int decimals) {
  final split = centimetresToFeetInches(centimetres);
  final inches = _roundTo(split.inches, decimals);
  return inches >= inchesPerFoot
      ? FeetInches(split.feet + 1, 0)
      : FeetInches(split.feet, inches);
}

/// [value] rounded to the [decimals] it prints with, so a sign, colour or arrow
/// taken from it agrees with the digits — `-0.004` at two places is zero.
///
/// Parsed back from [double.toStringAsFixed] rather than computed as
/// `(value * 100).round() / 100`, whose binary error can round the other way
/// from the printed text.
double _roundTo(double value, int decimals) =>
    double.parse(value.toStringAsFixed(decimals));

/// [value] at [decimals] places with an explicit `+` on a gain, and no sign
/// once it rounds to zero: `+0.05`, `-1.5`, `0.00`.
String _formatSigned(double value, int decimals) {
  final rounded = _roundTo(value, decimals);
  final magnitude = rounded.abs().toStringAsFixed(decimals);
  if (rounded > 0) return '+$magnitude';
  if (rounded < 0) return '-$magnitude';
  return magnitude;
}

/// A bare number with at most one decimal and no trailing `.0`, so a whole
/// height reads `178` rather than `178.0`.
String formatLengthValue(double value) {
  final text = value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

/// [centimetres] as it reads in [system]: `177.5 cm`, or `5' 10"`.
String formatHeight(double centimetres, MeasurementSystem system) {
  if (system == MeasurementSystem.metric) {
    return '${formatLengthValue(centimetres)} cm';
  }

  final split = roundedFeetInches(centimetres, 0);
  return "${split.feet}' ${formatLengthValue(split.inches)}\"";
}

/// Exact by definition, and the only place the pound is spelled out.
const double kilogramsPerPound = 0.45359237;

/// The places every weight and change in weight is shown to.
const int _weightDecimals = 2;

/// Chart axes are too narrow for [_weightDecimals], and a tick is a scale
/// mark rather than a reading.
const int _weightTickDecimals = 1;

double poundsToKilograms(double pounds) => pounds * kilogramsPerPound;

double kilogramsToPounds(double kilograms) => kilograms / kilogramsPerPound;

extension WeightDisplay on MeasurementSystem {
  String get weightSymbol => this == MeasurementSystem.imperial ? 'lbs' : 'kg';

  /// A stored weight as this system reads it. Everything is stored and computed
  /// in kilograms, so this is the only step between the store and the screen.
  double weightFromKilograms(double kilograms) =>
      this == MeasurementSystem.imperial
      ? kilogramsToPounds(kilograms)
      : kilograms;

  /// A figure typed in this system, back in kilograms for storage.
  double weightToKilograms(double value) =>
      this == MeasurementSystem.imperial ? poundsToKilograms(value) : value;

  /// [kilograms] as a bare number in this system, for a field or a label that
  /// names the unit elsewhere: `72.57`, `160.00`.
  String formatWeightValue(double kilograms) =>
      weightFromKilograms(kilograms).toStringAsFixed(_weightDecimals);

  /// [kilograms] as a chart axis tick: `72.5`, `160.0`.
  String formatWeightTick(double kilograms) =>
      weightFromKilograms(kilograms).toStringAsFixed(_weightTickDecimals);

  /// [kilograms] as it appears on screen: `72.57 kg`, `160.00 lbs`.
  String formatWeight(double kilograms) =>
      '${formatWeightValue(kilograms)} $weightSymbol';

  /// A stored change of [kilograms], in this system's unit (pounds under
  /// imperial) and rounded to what [formatWeightChange] prints.
  double shownWeightChange(double kilograms) =>
      _roundTo(weightFromKilograms(kilograms), _weightDecimals);

  /// A change of [kilograms] as it appears on screen: `+0.05 kg`, `-1.54 lbs`,
  /// `0.00 kg`.
  String formatWeightChange(double kilograms) =>
      '${_formatSigned(weightFromKilograms(kilograms), _weightDecimals)} '
      '$weightSymbol';
}
