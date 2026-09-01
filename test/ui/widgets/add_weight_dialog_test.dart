import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:food_locker/ui/widgets/add_weight_dialog.dart';

void main() {
  Future<void> pumpDialog(WidgetTester tester, DateTime initialDate) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(body: AddWeightDialog(initialDate: initialDate)),
      ),
    );
  }

  testWidgets('the date button renders the picked date locale-aware', (
    tester,
  ) async {
    final date = DateTime(2026, 3, 8);

    await pumpDialog(tester, date);

    expect(find.text(fullDate(date)), findsOneWidget);
  });
}
