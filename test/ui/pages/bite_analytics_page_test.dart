import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bite/data/bite_database.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/bite/data/drift_bite_repository.dart';
import 'package:food_locker/ui/pages/bite_analytics_page.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:food_locker/ui/widgets/stat_tile.dart';
import 'package:provider/provider.dart';

/// The stat tiles read against a seeded fixture, over a real in-memory Drift
/// store so the day-grouping query backs the numbers the tiles show.
void main() {
  late BiteDatabase db;
  late BiteRepository repo;

  setUp(() {
    db = BiteDatabase.forTesting(NativeDatabase.memory());
    repo = DriftBiteRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Logs [count] bites on [day], one per minute from 08:00.
  Future<void> logBites(DateTime day, int count) async {
    for (var i = 0; i < count; i++) {
      await repo.logBite(DateTime(day.year, day.month, day.day, 8, i));
    }
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<BiteRepository>.value(
        value: repo,
        child: MaterialApp(theme: appTheme, home: const BiteAnalyticsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tiles read the averages and max from the seeded fixture', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final longAgo = DateTime(now.year, now.month, now.day - 100);

    // 30-day window: today 50 + yesterday 60 → average 55, max 60 (yesterday).
    // 1-year window also folds in the 80-bite day 100 days back → average 63.
    await logBites(today, 50);
    await logBites(yesterday, 60);
    await logBites(longAgo, 80);

    await pumpPage(tester);

    expect(
      find.descendant(
        of: find.widgetWithText(StatTile, '30-day average'),
        matching: find.text('55'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(StatTile, '1-year average'),
        matching: find.text('63'),
      ),
      findsOneWidget,
    );
    final maxTile = find.widgetWithText(StatTile, '30-day max');
    expect(
      find.descendant(of: maxTile, matching: find.text('60')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: maxTile,
        matching: find.text('${yesterday.month}/${yesterday.day}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tiles show a dash when no day qualifies', (tester) async {
    // A handful of bites today, all below the 40-bite average threshold and the
    // only bites ever logged → averages have no qualifying day, max is that day.
    final now = DateTime.now();
    await logBites(DateTime(now.year, now.month, now.day), 5);

    await pumpPage(tester);

    // Both average tiles read '—'; the max still surfaces the 5-bite day.
    expect(
      find.descendant(
        of: find.widgetWithText(StatTile, '30-day average'),
        matching: find.text('—'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(StatTile, '1-year average'),
        matching: find.text('—'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(StatTile, '30-day max'),
        matching: find.text('5'),
      ),
      findsOneWidget,
    );
  });
}
