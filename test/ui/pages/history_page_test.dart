import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/days/data/day.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:food_locker/features/days/data/in_memory_food_day_repository.dart';
import 'package:food_locker/features/food/data/food.dart';
import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_type.dart';
import 'package:food_locker/features/food/data/in_memory_food_config_repository.dart';
import 'package:food_locker/features/weight/data/in_memory_weight_repository.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/ui/pages/history_page.dart';
import 'package:provider/provider.dart';
import 'package:food_locker/features/weight/data/weight.dart';
void main() {
  late FoodDayManager dayManager;
  late InMemoryFoodDayRepository foodDayRepository;
  late InMemoryFoodConfigRepository foodConfigRepository;
  late WeightManager weightManager;
  late InMemoryWeightRepository weightRepository;

  setUp(() {
    foodConfigRepository = InMemoryFoodConfigRepository([
      FoodConfig(name: 'Chicken', type: FoodType.meal),
    ]);
    foodDayRepository = InMemoryFoodDayRepository();
    weightRepository = InMemoryWeightRepository();
    weightManager = WeightManager(weightRepository);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FoodDayManager>.value(value: dayManager),
        ChangeNotifierProvider<WeightManager>.value(value: weightManager),
      ],
      child: const MaterialApp(home: Scaffold(body: HistoryPage())),
    );
  }

  Future<void> saveDays(int count) async {
    for (var i = 0; i < count; i++) {
      final date = DateTime(2023, 10, 1 + i);
      await foodDayRepository.saveDay(
        FoodDay(
          date: date,
          meals: [Food(name: 'Chicken', eatenTime: date)],
          snacks: [],
        ),
      );
    }
  }

  testWidgets('shows only 7 entries when history has more', (tester) async {
    await saveDays(10);
    dayManager = FoodDayManager(
      null,
      foodConfigRepository,
      foodDayRepository,
    );

    await tester.pumpWidget(createWidgetUnderTest());

    // Should show 7 day tiles + 1 Load More button
    expect(find.byType(ExpansionTile), findsNWidgets(7));
    expect(find.text('Load More'), findsOneWidget);
  });

  testWidgets('shows all entries when history has 7 or fewer', (tester) async {
    await saveDays(5);
    dayManager = FoodDayManager(
      null,
      foodConfigRepository,
      foodDayRepository,
    );

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(ExpansionTile), findsNWidgets(5));
    expect(find.text('Load More'), findsNothing);
  });

  testWidgets('Load More button shows next batch of entries', (tester) async {
    await saveDays(10);
    dayManager = FoodDayManager(
      null,
      foodConfigRepository,
      foodDayRepository,
    );

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(ExpansionTile), findsNWidgets(7));

    // Scroll to bottom to find the Load More button
    await tester.scrollUntilVisible(find.text('Load More'), 200);
    await tester.tap(find.text('Load More'));
    await tester.pumpAndSettle();

    // Now all 10 entries should be visible, no Load More
    expect(find.byType(ExpansionTile), findsNWidgets(10));
    expect(find.text('Load More'), findsNothing);
  });

  testWidgets('shows no history message when empty', (tester) async {
    dayManager = FoodDayManager(
      null,
      foodConfigRepository,
      foodDayRepository,
    );

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('No history available'), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
  });

  testWidgets('shows exactly 7 entries without Load More when history has 7',
      (tester) async {
    await saveDays(7);
    dayManager = FoodDayManager(
      null,
      foodConfigRepository,
      foodDayRepository,
    );

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(ExpansionTile), findsNWidgets(7));
    expect(find.text('Load More'), findsNothing);
  });

  testWidgets('shows warning icon for days marked as overate', (tester) async {
    await foodDayRepository.saveDay(
      FoodDay(
        date: DateTime(2023, 10, 1),
        meals: [Food(name: 'Chicken', eatenTime: DateTime(2023, 10, 1))],
        snacks: [],
      ),
    );
    await foodDayRepository.saveDay(
      FoodDay(
        date: DateTime(2023, 10, 2),
        meals: [Food(name: 'Chicken', eatenTime: DateTime(2023, 10, 2))],
        snacks: [],
      ),
    );

    // Setup weights to simulate overeating on 10/1 and not on 10/2
    await weightRepository.saveWeight(Weight(date: DateTime(2023, 10, 1), value: 70.0, unit: WeightUnit.kilograms));
    await weightRepository.saveWeight(Weight(date: DateTime(2023, 10, 2), value: 71.0, unit: WeightUnit.kilograms)); // Weight increased: 10/1 is overeaten
    await weightRepository.saveWeight(Weight(date: DateTime(2023, 10, 3), value: 70.0, unit: WeightUnit.kilograms)); // Weight decreased: 10/2 is not overeaten

    dayManager = FoodDayManager(
      null,
      foodConfigRepository,
      foodDayRepository,
    );
    await weightManager.initialize();

    await tester.pumpWidget(createWidgetUnderTest());

    // Should find exactly one warning icon (for the overate day)
    expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
  });
}
