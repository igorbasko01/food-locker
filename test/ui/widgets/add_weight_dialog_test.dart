import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:food_locker/ui/widgets/add_weight_dialog.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester,
    DateTime initialDate, {
    MeasurementSystem system = MeasurementSystem.metric,
    double? initialWeight,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: AddWeightDialog(
            initialDate: initialDate,
            initialWeight: initialWeight,
            system: system,
          ),
        ),
      ),
    );
  }

  /// The map the dialog pops, captured by pushing it from a route.
  Future<Map<String, dynamic>?> submit(
    WidgetTester tester, {
    required MeasurementSystem system,
    double? initialWeight,
    String? typed,
  }) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (_) => AddWeightDialog(
                    initialDate: DateTime(2026, 3, 8),
                    initialWeight: initialWeight,
                    system: system,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    if (typed != null) {
      await tester.enterText(find.byType(TextField), typed);
    }
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    return result;
  }

  testWidgets('the date button renders the picked date locale-aware', (
    tester,
  ) async {
    final date = DateTime(2026, 3, 8);

    await pumpDialog(tester, date);

    expect(find.text(fullDateWithWeekday(date)), findsOneWidget);
  });

  testWidgets('the field is labelled with the system being typed', (
    tester,
  ) async {
    await pumpDialog(tester, DateTime(2026, 3, 8));
    expect(find.text('Weight (kg)'), findsOneWidget);

    await pumpDialog(
      tester,
      DateTime(2026, 3, 8),
      system: MeasurementSystem.imperial,
    );
    expect(find.text('Weight (lbs)'), findsOneWidget);
  });

  testWidgets('an existing entry prefills in the preferred system', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      DateTime(2026, 3, 8),
      system: MeasurementSystem.imperial,
      initialWeight: 72.5748,
    );

    expect(find.text('160.0'), findsOneWidget);
  });

  testWidgets('a whole-pound entry saves as kilograms', (tester) async {
    final result = await submit(
      tester,
      system: MeasurementSystem.imperial,
      typed: '160',
    );

    expect(result!['value'] as double, closeTo(72.5748, 1e-4));
  });

  testWidgets('a one-decimal pound entry saves as kilograms', (tester) async {
    final result = await submit(
      tester,
      system: MeasurementSystem.imperial,
      typed: '159.8',
    );

    expect(result!['value'] as double, closeTo(72.4841, 1e-4));
  });

  testWidgets('kilograms are stored as typed', (tester) async {
    final result = await submit(
      tester,
      system: MeasurementSystem.metric,
      typed: '75.5',
    );

    expect(result!['value'] as double, 75.5);
  });

  testWidgets('saving an untouched imperial edit leaves the stored kg exact', (
    tester,
  ) async {
    const stored = 72.57432;

    final result = await submit(
      tester,
      system: MeasurementSystem.imperial,
      initialWeight: stored,
    );

    expect(result!['value'] as double, stored);
  });

  testWidgets('a deliberate imperial edit converts the new figure', (
    tester,
  ) async {
    final result = await submit(
      tester,
      system: MeasurementSystem.imperial,
      initialWeight: 72.57432,
      typed: '158.0',
    );

    expect(result!['value'] as double, closeTo(71.6676, 1e-3));
  });

  testWidgets('a non-positive entry does not pop a value', (tester) async {
    await pumpDialog(tester, DateTime(2026, 3, 8));

    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Log Weight'), findsOneWidget);
  });
}
