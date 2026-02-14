import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_config_repository.dart';
import 'package:food_locker/features/food/data/food_type.dart';
import 'package:food_locker/features/food/data/in_memory_food_config_repository.dart';
import 'package:food_locker/ui/pages/settings_page.dart';
import 'package:provider/provider.dart';

void main() {
  late FoodConfigRepository repository;

  setUp(() {
    repository = InMemoryFoodConfigRepository([]);
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<FoodConfigRepository>.value(
      value: repository,
      child: const MaterialApp(home: SettingsPage()),
    );
  }

  testWidgets('shows snackbar when adding duplicate food config', (
    tester,
  ) async {
    // Add initial config
    repository.add(FoodConfig(name: 'Pizza', type: FoodType.meal));

    await tester.pumpWidget(createWidgetUnderTest());

    // Tap Add button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Enter "Pizza"
    await tester.enterText(find.byType(TextField), 'Pizza');
    // Select Meal (default)

    // Tap Add in Dialog
    await tester.tap(find.text('Add'));
    await tester.pump(); // Start animation

    // Verify SnackBar
    expect(find.text('Food config already exists'), findsOneWidget);

    // Verify Dialog is still open (Add button still visible)
    expect(find.text('Add'), findsOneWidget);

    // Config count should still be 1
    expect(repository.foodConfigs.length, 1);
  });

  testWidgets('adds unique food config', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Tap Add button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Enter "Burger"
    await tester.enterText(find.byType(TextField), 'Burger');

    // Tap Add in Dialog
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle(); // Wait for dialog to close

    // Verify config added
    expect(repository.foodConfigs.length, 1);
    expect(repository.foodConfigs.first.name, 'Burger');
    expect(find.text('Burger'), findsOneWidget);
  });
}
