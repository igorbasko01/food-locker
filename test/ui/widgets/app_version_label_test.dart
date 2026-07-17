import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/ui/widgets/app_version_label.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: Scaffold(
        body: AppVersionLabel(),
      ),
    );
  }

  testWidgets('AppVersionLabel shows the installed version', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'food_locker',
      packageName: 'com.example.food_locker',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Version 1.2.3'), findsOneWidget);
  });
}
