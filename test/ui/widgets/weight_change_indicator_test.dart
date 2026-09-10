import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/ui/widgets/weight_change_indicator.dart';

void main() {
  Widget createWidgetUnderTest(
    double? diff, [
    MeasurementSystem system = MeasurementSystem.metric,
  ]) {
    return MaterialApp(
      home: Scaffold(
        body: WeightChangeIndicator(diff: diff, system: system),
      ),
    );
  }

  testWidgets('shows Baseline when diff is null', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(null));
    expect(find.text('Baseline'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
  });

  testWidgets('shows positive difference with + sign and up arrow', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(1.5));
    expect(find.text('+1.5 kg'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
  });

  testWidgets('shows negative difference with - sign and down arrow', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(-0.8));
    expect(find.text('-0.8 kg'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
  });

  testWidgets('shows 0.0 kg and neutral icon when diff is 0', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(0.0));
    expect(find.text('0.0 kg'), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
  });

  testWidgets('converts the kilogram diff under imperial', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(2.4, MeasurementSystem.imperial),
    );
    expect(find.text('+5.3 lbs'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
  });

  testWidgets('a loss keeps its sign through the conversion', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(-0.9071847, MeasurementSystem.imperial),
    );
    expect(find.text('-2.0 lbs'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
  });
}
