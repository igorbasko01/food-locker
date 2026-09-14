/// The WHO adult BMI bands.
enum BmiCategory { underweight, healthy, overweight, obese }

/// The band cut-offs, as half-open intervals: a value belongs to the band whose
/// lower bound it reaches without reaching the next one, so 25.0 is overweight
/// rather than the top of healthy and no value between two bands is homeless.
const double healthyBmiFrom = 18.5;
const double overweightBmiFrom = 25.0;
const double obeseBmiFrom = 30.0;

/// A stored weight is read as kilograms whatever its `WeightUnit` says, and
/// [heightCm] is the only length unit the store keeps.
double bodyMassIndex({required double kilograms, required double heightCm}) {
  final metres = heightCm / 100;
  return kilograms / (metres * metres);
}

BmiCategory bmiCategory(double bmi) {
  if (bmi < healthyBmiFrom) return BmiCategory.underweight;
  if (bmi < overweightBmiFrom) return BmiCategory.healthy;
  if (bmi < obeseBmiFrom) return BmiCategory.overweight;
  return BmiCategory.obese;
}

/// The half-open BMI interval [from, to) a category covers. The open-ended
/// bands carry infinite edges; a caller drawing them has to bound them itself.
class BmiBand {
  const BmiBand(this.category, this.from, this.to);

  final BmiCategory category;
  final double from;
  final double to;

  static const List<BmiBand> all = [
    BmiBand(BmiCategory.underweight, double.negativeInfinity, healthyBmiFrom),
    BmiBand(BmiCategory.healthy, healthyBmiFrom, overweightBmiFrom),
    BmiBand(BmiCategory.overweight, overweightBmiFrom, obeseBmiFrom),
    BmiBand(BmiCategory.obese, obeseBmiFrom, double.infinity),
  ];
}
