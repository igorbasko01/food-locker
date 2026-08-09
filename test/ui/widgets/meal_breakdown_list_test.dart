import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:food_locker/ui/widgets/meal_breakdown_list.dart';

void main() {
  Future<void> pumpList(WidgetTester tester, DayMealBreakdown breakdown) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(body: MealBreakdownList(breakdown: breakdown)),
      ),
    );
  }

  final day = DateTime(2026, 7, 16);

  testWidgets('renders a row per meal with its count and the snack total', (
    tester,
  ) async {
    await pumpList(
      tester,
      DayMealBreakdown(
        day: day,
        meals: [
          Meal(
            start: DateTime(2026, 7, 16, 8, 0),
            end: DateTime(2026, 7, 16, 8, 11),
            count: 12,
          ),
          Meal(
            start: DateTime(2026, 7, 16, 13, 30),
            end: DateTime(2026, 7, 16, 13, 44),
            count: 15,
          ),
        ],
        snackBites: 5,
      ),
    );

    expect(find.text('Meal 1'), findsOneWidget);
    expect(find.text('Meal 2'), findsOneWidget);
    expect(find.text('12 bites'), findsOneWidget);
    expect(find.text('15 bites'), findsOneWidget);
    expect(find.text('Snacks'), findsOneWidget);
    expect(find.text('5 bites'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('32 bites'), findsOneWidget);
    // A morning and an afternoon meal read as 12-hour times.
    expect(find.text('8:00 AM – 8:11 AM'), findsOneWidget);
    expect(find.text('1:30 PM – 1:44 PM'), findsOneWidget);
  });

  testWidgets('renders the snack total on an all-snack day with no meals', (
    tester,
  ) async {
    await pumpList(
      tester,
      DayMealBreakdown(day: day, meals: const [], snackBites: 8),
    );

    expect(find.text('Meal 1'), findsNothing);
    expect(find.text('Snacks'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    // Snack row and total row, both reading the day's only 8 bites.
    expect(find.text('8 bites'), findsNWidgets(2));
  });

  testWidgets('shows the empty state when the day has no bites', (tester) async {
    await pumpList(
      tester,
      DayMealBreakdown(day: day, meals: const [], snackBites: 0),
    );

    expect(find.text('No bites logged today yet.'), findsOneWidget);
    expect(find.text('Snacks'), findsNothing);
    expect(find.text('Total'), findsNothing);
  });
}
