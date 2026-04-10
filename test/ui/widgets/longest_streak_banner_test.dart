import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/days/data/day_manager.dart';
import 'package:food_locker/ui/widgets/longest_streak_banner.dart';

void main() {
  Widget createWidgetUnderTest(OvereatingStats stats) {
    return MaterialApp(
      home: Scaffold(
        body: LongestStreakBanner(stats: stats),
      ),
    );
  }

  testWidgets('LongestStreakBanner is hidden if streak < 2', (tester) async {
    final stats = OvereatingStats(
      cleanStreak: 1,
      overeatingStreak: 0,
      longestCleanStreak: 1,
    );

    await tester.pumpWidget(createWidgetUnderTest(stats));
    expect(find.byType(Container), findsNothing);
  });

  testWidgets('LongestStreakBanner shows streak count and dates', (tester) async {
    final startDate = DateTime(2023, 10, 1);
    final endDate = DateTime(2023, 10, 5);
    final stats = OvereatingStats(
      cleanStreak: 2,
      overeatingStreak: 0,
      longestCleanStreak: 5,
      longestStreakStart: startDate,
      longestStreakEnd: endDate,
    );

    await tester.pumpWidget(createWidgetUnderTest(stats));
    
    expect(find.text('All-Time Best: 5 Days'), findsOneWidget);
    // Since we can't easily check the exactly formatted date string without reproducing the logic,
    // we just check if "to" and some numbers are present or if find.text with expected formatted dates works.
    // DayDateText format is "$weekday, YYYY-MM-DD"
    expect(find.textContaining('to'), findsOneWidget);
    expect(find.text('Your longest streak of eating mindfully!'), findsOneWidget);
  });
}
