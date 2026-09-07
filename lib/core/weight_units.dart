/// Exact by definition, and the only place the pound is spelled out.
const double kilogramsPerPound = 0.45359237;

double poundsToKilograms(double pounds) => pounds * kilogramsPerPound;

double kilogramsToPounds(double kilograms) => kilograms / kilogramsPerPound;
