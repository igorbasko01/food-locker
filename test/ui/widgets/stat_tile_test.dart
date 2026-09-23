import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/ui/theme.dart';
import 'package:food_locker/ui/widgets/stat_tile.dart';

void main() {
  Future<void> pumpTile(WidgetTester tester, StatTile tile) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(body: Center(child: tile)),
      ),
    );
  }

  /// The tile as the Weight tab lays it out: a third of a phone's width, in a
  /// row stretched to the height its tallest member intrinsically needs.
  Future<double> stretchedHeight(WidgetTester tester, String value) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 104,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StatTile(label: 'Weekly change', value: value),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return tester.getSize(find.byType(StatTile)).height;
  }

  testWidgets('a figure wider than the tile scales instead of taking a line', (
    tester,
  ) async {
    final long = await stretchedHeight(tester, '-0.70 kg/wk');
    final short = await stretchedHeight(tester, '--');

    expect(long, short);
  });

  testWidgets('renders the label, value, and sub-label', (tester) async {
    await pumpTile(
      tester,
      const StatTile(label: '30-day max', value: '60', subLabel: '7/14'),
    );

    expect(find.text('30-day max'), findsOneWidget);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('7/14'), findsOneWidget);
  });

  testWidgets('reserves the sub-line even without a sub-label', (tester) async {
    await pumpTile(
      tester,
      const StatTile(label: '30-day average', value: '55'),
    );

    expect(find.text('30-day average'), findsOneWidget);
    expect(find.text('55'), findsOneWidget);
    // The sub-line is present but empty, keeping tile heights aligned.
    expect(find.text(''), findsOneWidget);
  });

  testWidgets('reads as one semantics node including the sub-label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpTile(
      tester,
      const StatTile(label: '30-day max', value: '60', subLabel: '7/14'),
    );

    expect(find.bySemanticsLabel('30-day max: 60, 7/14'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('omits the sub-label from semantics when absent', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTile(
      tester,
      const StatTile(label: '30-day average', value: '55'),
    );

    expect(find.bySemanticsLabel('30-day average: 55'), findsOneWidget);
    handle.dispose();
  });
}
