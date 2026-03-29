import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:food_locker/ui/widgets/streak_banner.dart';

void main() {
  Widget createWidgetUnderTest(OvereatingStats stats) {
    return MaterialApp(
      home: Scaffold(
        body: StreakBanner(stats: stats),
      ),
    );
  }

  testWidgets('shows Welcome when both streaks are 0', (tester) async {
    final stats = OvereatingStats(
      cleanStreak: 0,
      overeatingStreak: 0,
    );

    await tester.pumpWidget(createWidgetUnderTest(stats));
    expect(find.text('Welcome!'), findsOneWidget);
  });

  testWidgets('shows Overeating Streak when overeatingStreak >= 2', (tester) async {
    final stats = OvereatingStats(
      cleanStreak: 0,
      overeatingStreak: 3,
    );

    await tester.pumpWidget(createWidgetUnderTest(stats));
    expect(find.text('3-Day Overeating Streak'), findsOneWidget);
  });

  testWidgets('shows Fresh Start! when overeatingStreak == 1', (tester) async {
    final stats = OvereatingStats(
      cleanStreak: 0,
      overeatingStreak: 1,
    );

    await tester.pumpWidget(createWidgetUnderTest(stats));
    expect(find.text('Fresh Start!'), findsOneWidget);
  });

  testWidgets('shows Streak! when cleanStreak >= 2', (tester) async {
    final stats = OvereatingStats(
      cleanStreak: 5,
      overeatingStreak: 0,
    );

    await tester.pumpWidget(createWidgetUnderTest(stats));
    expect(find.text('5-Day Streak!'), findsOneWidget);
  });

  testWidgets('shows Good Job! when cleanStreak == 1', (tester) async {
    final stats = OvereatingStats(
      cleanStreak: 1,
      overeatingStreak: 0,
    );

    await tester.pumpWidget(createWidgetUnderTest(stats));
    expect(find.text('Good Job!'), findsOneWidget);
  });
}
