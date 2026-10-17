import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/weight/data/weight.dart';

void main() {
  const metric = MeasurementSystem.metric;
  const imperial = MeasurementSystem.imperial;

  group('Weight', () {
    test('stringify renders two decimals and the system symbol', () {
      final weight = Weight(72.5748, metric);
      expect(weight.stringify(metric), '72.57 kg');
      expect(weight.stringify(imperial), '160.00 lbs');
      expect(Weight(72.5, metric).stringify(metric), '72.50 kg');
    });

    test('stringify takes fewer decimals and drops the symbol when asked', () {
      final weight = Weight(72.5748, metric);
      expect(weight.stringify(metric, decimals: 1), '72.6 kg');
      expect(
        weight.stringify(imperial, decimals: 1, withSymbol: false),
        '160.0',
      );
      expect(Weight(72.3, metric).stringify(metric, withSymbol: false), '72.30');
    });

    test('value reads the amount in the system', () {
      final weight = Weight(72.5748, metric);
      expect(weight.value(metric), 72.5748);
      expect(weight.value(imperial), closeTo(160, 1e-3));
    });

    test('a figure given in one system reads back in the other', () {
      expect(Weight(160, imperial).value(metric), closeTo(72.5748, 1e-4));
      expect(Weight(75.5, metric).value(metric), 75.5);
    });

    test('diff is this weight minus the other', () {
      final today = Weight(89.40, metric);
      final yesterday = Weight(89.45, metric);
      expect(today.diff(yesterday).value(metric), closeTo(-0.05, 1e-9));
      expect(yesterday.diff(today).value(metric), closeTo(0.05, 1e-9));
    });

    test('mean averages the weights, and is null for none', () {
      expect(
        Weight.mean([Weight(80, metric), Weight(81, metric)]),
        Weight(80.5, metric),
      );
      expect(Weight.mean(const []), isNull);
    });

    test('compares by amount', () {
      expect(Weight(72, metric) < Weight(73, metric), isTrue);
      expect(Weight(73, metric) < Weight(72, metric), isFalse);
    });
  });

  group('WeightChange', () {
    test('stringify signs a gain and a loss in the system', () {
      final today = Weight(89.40, metric);
      final yesterday = Weight(89.45, metric);
      expect(today.diff(yesterday).stringify(metric), '-0.05 kg');
      expect(WeightChange(1.4, metric).stringify(metric), '+1.40 kg');
      expect(WeightChange(0.7, metric).stringify(imperial), '+1.54 lbs');
    });

    test('a change too small to show is an unsigned zero', () {
      final change = WeightChange(-0.004, metric);
      expect(change.stringify(metric), '0.00 kg');
      expect(change.value(metric), 0);
    });

    test('value is rounded to what stringify prints, in the system', () {
      final change = WeightChange(0.7, metric);
      expect(change.value(imperial), closeTo(1.54, 1e-9));
      expect(change.value(imperial, decimals: 1), closeTo(1.5, 1e-9));
      expect(change.stringify(imperial, decimals: 1), '+1.5 lbs');
    });

    test('scales, as a weekly trend projected over a month', () {
      expect(
        (WeightChange(-0.7, metric) * (30 / 7)).stringify(metric),
        '-3.00 kg',
      );
    });
  });
}
