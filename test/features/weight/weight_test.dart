import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/weight/data/weight.dart';

void main() {
  group('Weight', () {
    test('stringify renders two decimals and the system symbol', () {
      const weight = Weight.kilograms(72.5748);
      expect(weight.stringify(MeasurementSystem.metric), '72.57 kg');
      expect(weight.stringify(MeasurementSystem.imperial), '160.00 lbs');
      expect(
        const Weight.kilograms(72.5).stringify(MeasurementSystem.metric),
        '72.50 kg',
      );
    });

    test('stringify takes fewer decimals and drops the symbol when asked', () {
      const weight = Weight.kilograms(72.5748);
      expect(
        weight.stringify(MeasurementSystem.metric, decimals: 1),
        '72.6 kg',
      );
      expect(
        weight.stringify(
          MeasurementSystem.imperial,
          decimals: 1,
          withSymbol: false,
        ),
        '160.0',
      );
      expect(
        const Weight.kilograms(72.3).stringify(
          MeasurementSystem.metric,
          withSymbol: false,
        ),
        '72.30',
      );
    });

    test('value reads the amount in the system', () {
      const weight = Weight.kilograms(72.5748);
      expect(weight.value(MeasurementSystem.metric), 72.5748);
      expect(weight.value(MeasurementSystem.imperial), closeTo(160, 1e-3));
    });

    test('inSystem takes a typed figure back to the same amount', () {
      expect(
        Weight.inSystem(160, MeasurementSystem.imperial).kilograms,
        closeTo(72.5748, 1e-4),
      );
      expect(Weight.inSystem(75.5, MeasurementSystem.metric).kilograms, 75.5);
    });

    test('diff is this weight minus the other', () {
      const today = Weight.kilograms(89.40);
      const yesterday = Weight.kilograms(89.45);
      expect(today.diff(yesterday).kilograms, closeTo(-0.05, 1e-9));
      expect(yesterday.diff(today).kilograms, closeTo(0.05, 1e-9));
    });

    test('mean averages the weights, and is null for none', () {
      expect(
        Weight.mean(const [Weight.kilograms(80), Weight.kilograms(81)]),
        const Weight.kilograms(80.5),
      );
      expect(Weight.mean(const []), isNull);
    });

    test('compares by amount', () {
      expect(const Weight.kilograms(72) < const Weight.kilograms(73), isTrue);
      expect(const Weight.kilograms(73) < const Weight.kilograms(72), isFalse);
    });
  });

  group('WeightChange', () {
    test('stringify signs a gain and a loss in the system', () {
      const today = Weight.kilograms(89.40);
      const yesterday = Weight.kilograms(89.45);
      expect(
        today.diff(yesterday).stringify(MeasurementSystem.metric),
        '-0.05 kg',
      );
      expect(
        const WeightChange.kilograms(1.4).stringify(MeasurementSystem.metric),
        '+1.40 kg',
      );
      expect(
        const WeightChange.kilograms(0.7).stringify(MeasurementSystem.imperial),
        '+1.54 lbs',
      );
    });

    test('a change too small to show is an unsigned zero', () {
      const change = WeightChange.kilograms(-0.004);
      expect(change.stringify(MeasurementSystem.metric), '0.00 kg');
      expect(change.value(MeasurementSystem.metric), 0);
    });

    test('value is rounded to what stringify prints, in the system', () {
      const change = WeightChange.kilograms(0.7);
      expect(change.value(MeasurementSystem.imperial), closeTo(1.54, 1e-9));
      expect(
        change.value(MeasurementSystem.imperial, decimals: 1),
        closeTo(1.5, 1e-9),
      );
      expect(
        change.stringify(MeasurementSystem.imperial, decimals: 1),
        '+1.5 lbs',
      );
    });

    test('scales, as a weekly trend projected over a month', () {
      expect(
        (const WeightChange.kilograms(-0.7) * (30 / 7)).stringify(
          MeasurementSystem.metric,
        ),
        '-3.00 kg',
      );
    });
  });

  group('WeightEntry', () {
    test('weight is the stored kilograms as a Weight', () {
      final entry = WeightEntry(date: DateTime(2026, 10, 14), kilograms: 89.4);
      expect(entry.weight, const Weight.kilograms(89.4));
    });
  });
}
