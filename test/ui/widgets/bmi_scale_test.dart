import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:food_locker/ui/widgets/bmi_scale.dart';

void main() {
  Future<void> pumpScale(WidgetTester tester, double bmi) => tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(body: BmiScale(bmi: bmi)),
        ),
      );

  group('markerFraction', () {
    test('runs 0 to 1 across the drawn domain', () {
      expect(BmiScale.markerFraction(BmiScale.domainFrom), 0.0);
      expect(BmiScale.markerFraction(BmiScale.domainTo), 1.0);
      expect(BmiScale.markerFraction(25.0), closeTo(0.5, 0.000001));
    });

    test('pins to the ends outside it', () {
      expect(BmiScale.markerFraction(11.0), 0.0);
      expect(BmiScale.markerFraction(64.0), 1.0);
    });
  });

  testWidgets('captions the value to one decimal beside its band', (tester) async {
    await pumpScale(tester, 24.14);

    expect(find.text('24.1 · Healthy'), findsOneWidget);
  });

  testWidgets('bands the figure as printed, not as computed', (tester) async {
    await pumpScale(tester, 24.96);

    expect(find.text('25.0 · Overweight'), findsOneWidget);
  });

  testWidgets('a clamped marker still captions the true value', (tester) async {
    await pumpScale(tester, 52.3);

    expect(find.text('52.3 · Obese'), findsOneWidget);
  });

  testWidgets('names every band in text, never colour alone', (tester) async {
    await pumpScale(tester, 22.0);

    expect(find.text('Under'), findsOneWidget);
    expect(find.text('Healthy'), findsOneWidget);
    expect(find.text('Over'), findsOneWidget);
    expect(find.text('Obese'), findsOneWidget);
  });

  testWidgets('speaks as one phrase', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScale(tester, 17.02);

    expect(
      find.bySemanticsLabel('BMI 17.0, underweight range'),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('sizes the segments in proportion to their ranges', (tester) async {
    await pumpScale(tester, 22.0);

    double segmentWidth(String label) => tester
        .getRect(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(Container),
          ).first,
        )
        .width;

    // Drawn spans: 3.5 / 6.5 / 5 / 5 BMI points of the 15-35 domain, so the
    // healthy band is the widest of the four.
    expect(segmentWidth('Healthy') / segmentWidth('Under'),
        closeTo(6.5 / 3.5, 0.05));
    expect(segmentWidth('Obese') / segmentWidth('Healthy'),
        closeTo(5 / 6.5, 0.05));
    expect(segmentWidth('Obese') / segmentWidth('Over'), closeTo(1.0, 0.05));
  });

  testWidgets('prints each cut-off under the seam it belongs to', (
    tester,
  ) async {
    await pumpScale(tester, 22.0);

    double segmentRight(String label) => tester
        .getRect(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(Container),
          ).first,
        )
        .right;

    expect(
      tester.getCenter(find.text('18.5')).dx,
      closeTo(segmentRight('Under'), 1.0),
    );
    expect(
      tester.getCenter(find.text('25')).dx,
      closeTo(segmentRight('Healthy'), 1.0),
    );
    expect(
      tester.getCenter(find.text('30')).dx,
      closeTo(segmentRight('Over'), 1.0),
    );
  });

  testWidgets('puts the marker at the value, and at the edge past the domain',
      (tester) async {
    Rect bar() => tester.getRect(find.byKey(BmiScale.barKey));
    double marker() =>
        tester.getCenter(find.byIcon(Icons.arrow_drop_down)).dx;

    await pumpScale(tester, 25.0);
    expect(marker(), closeTo(bar().center.dx, 1.0));

    // A quarter of the way along the domain is a quarter along the bar.
    await pumpScale(tester, 20.0);
    expect(marker(), closeTo(bar().left + 0.25 * bar().width, 1.0));

    await pumpScale(tester, 64.0);
    expect(marker(), closeTo(bar().right, 16.0));
    expect(marker(), greaterThan(bar().center.dx));
  });

  testWidgets('marker lands inside the band the caption names', (tester) async {
    await pumpScale(tester, 18.4);

    final marker = tester.getCenter(find.byIcon(Icons.arrow_drop_down)).dx;
    final underweight = tester.getRect(
      find
          .ancestor(of: find.text('Under'), matching: find.byType(Container))
          .first,
    );

    expect(find.text('18.4 · Underweight'), findsOneWidget);
    expect(marker, greaterThanOrEqualTo(underweight.left));
    expect(marker, lessThan(underweight.right));
  });
}
