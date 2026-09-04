import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/ui/widgets/height_dialog.dart';

/// What the height editor is allowed to hand back: centimetres, unchanged when
/// nothing was typed, and nothing at all while the input is implausible.
void main() {
  double? popped;
  bool closed = false;

  Future<void> openDialog(
    WidgetTester tester, {
    double? initialHeightCm,
    MeasurementSystem system = MeasurementSystem.metric,
  }) async {
    popped = null;
    closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                popped = await showDialog<double>(
                  context: context,
                  builder: (_) => HeightDialog(
                    initialHeightCm: initialHeightCm,
                    system: system,
                  ),
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  group('metric', () {
    testWidgets('stores what was typed in centimetres', (tester) async {
      await openDialog(tester);

      await tester.enterText(find.byKey(HeightDialog.centimetresFieldKey), '178');
      await save(tester);

      expect(popped, 178);
    });

    testWidgets('accepts a decimal', (tester) async {
      await openDialog(tester);

      await tester.enterText(
        find.byKey(HeightDialog.centimetresFieldKey),
        '177.5',
      );
      await save(tester);

      expect(popped, 177.5);
    });

    testWidgets('an untouched field returns the stored value unchanged',
        (tester) async {
      await openDialog(tester, initialHeightCm: 178.23);

      await save(tester);

      expect(popped, 178.23);
    });

    testWidgets('rejects an implausible height', (tester) async {
      await openDialog(tester);

      await tester.enterText(find.byKey(HeightDialog.centimetresFieldKey), '10');
      await save(tester);

      expect(find.textContaining('between'), findsOneWidget);
      expect(closed, isFalse);
    });

    testWidgets('rejects something that is not a number', (tester) async {
      await openDialog(tester);

      await tester.enterText(
        find.byKey(HeightDialog.centimetresFieldKey),
        'tall',
      );
      await save(tester);

      expect(find.text('Enter your height in centimetres'), findsOneWidget);
      expect(closed, isFalse);
    });
  });

  group('imperial', () {
    testWidgets('converts feet and inches to centimetres', (tester) async {
      await openDialog(tester, system: MeasurementSystem.imperial);

      await tester.enterText(find.byKey(HeightDialog.feetFieldKey), '5');
      await tester.enterText(find.byKey(HeightDialog.inchesFieldKey), '10');
      await save(tester);

      expect(popped, closeTo(177.8, 1e-9));
    });

    testWidgets('an empty inches field reads as a round number of feet',
        (tester) async {
      await openDialog(tester, system: MeasurementSystem.imperial);

      await tester.enterText(find.byKey(HeightDialog.feetFieldKey), '6');
      await save(tester);

      expect(popped, closeTo(182.88, 1e-9));
    });

    testWidgets('untouched fields return the stored centimetres, undrifted',
        (tester) async {
      // 178.23 cm has no exact feet-and-inches form, so a re-derived value
      // would come back slightly different.
      await openDialog(
        tester,
        initialHeightCm: 178.23,
        system: MeasurementSystem.imperial,
      );

      await save(tester);

      expect(popped, 178.23);
    });

    testWidgets('rejects twelve inches rather than rolling over a foot',
        (tester) async {
      await openDialog(tester, system: MeasurementSystem.imperial);

      await tester.enterText(find.byKey(HeightDialog.feetFieldKey), '5');
      await tester.enterText(find.byKey(HeightDialog.inchesFieldKey), '12');
      await save(tester);

      expect(find.text('Inches must be less than 12'), findsOneWidget);
      expect(closed, isFalse);
    });

    testWidgets('rejects an implausible height', (tester) async {
      await openDialog(tester, system: MeasurementSystem.imperial);

      await tester.enterText(find.byKey(HeightDialog.feetFieldKey), '1');
      await tester.enterText(find.byKey(HeightDialog.inchesFieldKey), '2');
      await save(tester);

      expect(find.textContaining('between'), findsOneWidget);
      expect(closed, isFalse);
    });
  });

  testWidgets('cancelling stores nothing', (tester) async {
    await openDialog(tester, initialHeightCm: 178);

    await tester.enterText(find.byKey(HeightDialog.centimetresFieldKey), '150');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(popped, isNull);
  });
}
