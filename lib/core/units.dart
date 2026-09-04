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

  final split = centimetresToFeetInches(centimetres);
  var feet = split.feet;
  var inches = split.inches.round();
  // Rounding 11.6" up would otherwise print 12".
  if (inches == inchesPerFoot) {
    feet += 1;
    inches = 0;
  }
  return "$feet' $inches\"";
}
