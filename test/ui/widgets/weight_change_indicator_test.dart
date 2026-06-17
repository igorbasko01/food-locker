import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/ui/widgets/weight_change_indicator.dart';

void main() {
  Widget createWidgetUnderTest(double? diff, [WeightUnit unit = WeightUnit.kilograms]) {
    return MaterialApp(
      home: Scaffold(
        body: WeightChangeIndicator(diff: diff, unit: unit),
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

  testWidgets('shows pounds suffix when WeightUnit.pounds is passed', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(2.4, WeightUnit.pounds));
    expect(find.text('+2.4 lbs'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
  });
}
