import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/ui/widgets/streak_banner.dart';

void main() {
  Widget createWidgetUnderTest(OvereatingStats stats) {
    return MaterialApp(
      home: Scaffold(
        body: StreakBanner(stats: stats),
      ),
    );
  }

  testWidgets('shows Start a new streak! when both streaks are 0', (tester) async {
    final stats = OvereatingStats();

    await tester.pumpWidget(createWidgetUnderTest(stats));
    expect(find.text('Start a new streak!'), findsOneWidget);
  });

  testWidgets('shows Overeating Streak when overeatingStreak >= 2', (tester) async {
    final stats = OvereatingStats(
      currentStreakType: StreakType.overeating,
      currentStreakStart: DateTime(2023, 10, 24),
      currentStreakEnd: DateTime(2023, 10, 26),
    );

    await tester.pumpWidget(createWidgetUnderTest(stats));
    expect(find.text('3-Day Overeating Streak'), findsOneWidget);
  });

  testWidgets('shows Fresh Start! when overeatingStreak == 1', (tester) async {
    final stats = OvereatingStats(
      currentStreakType: StreakType.overeating,
      currentStreakStart: DateTime(2023, 10, 26),
      currentStreakEnd: DateTime(2023, 10, 26),
    );

    await tester.pumpWidget(createWidgetUnderTest(stats));
    expect(find.text('Fresh Start!'), findsOneWidget);
  });

  testWidgets('shows Streak! when cleanStreak >= 2', (tester) async {
    final stats = OvereatingStats(
      currentStreakType: StreakType.clean,
      currentStreakStart: DateTime(2023, 10, 22),
      currentStreakEnd: DateTime(2023, 10, 26),
    );

    await tester.pumpWidget(createWidgetUnderTest(stats));
    expect(find.text('5-Day Streak!'), findsOneWidget);
  });

  testWidgets('shows Good Job! when cleanStreak == 1', (tester) async {
    final stats = OvereatingStats(
      currentStreakType: StreakType.clean,
      currentStreakStart: DateTime(2023, 10, 26),
      currentStreakEnd: DateTime(2023, 10, 26),
    );

    await tester.pumpWidget(createWidgetUnderTest(stats));
    expect(find.text('Good Job!'), findsOneWidget);
  });
}
