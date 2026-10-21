import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/bracelet/data/bracelet_connection.dart';
import 'package:food_locker/features/bracelet/data/bracelet_manager.dart';
import 'package:food_locker/features/bracelet/data/bracelet_status.dart';
import 'package:food_locker/ui/pages/bracelet_page.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_bracelet_connection.dart';

const _band = BraceletScanResult(id: 'AA:BB', name: 'BaskoBiteTracker', rssi: -61);

void main() {
  late FakeBraceletConnection connection;
  late BraceletManager manager;

  setUp(() {
    connection = FakeBraceletConnection()..found = const [_band];
    manager = BraceletManager(connection);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    // Tall enough to show the whole connected view.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<BraceletManager>.value(
        value: manager,
        child: const MaterialApp(home: BraceletPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> connect(WidgetTester tester) async {
    await tester.runAsync(() => manager.connect(_band));
    await tester.pumpAndSettle();
  }

  group('disconnected', () {
    testWidgets('scans on open and lists the bracelets found', (tester) async {
      connection.holdScans = true;
      await tester.pumpWidget(
        ChangeNotifierProvider<BraceletManager>.value(
          value: manager,
          child: const MaterialApp(home: BraceletPage()),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Disconnected'), findsOneWidget);
      expect(find.text('BaskoBiteTracker'), findsOneWidget);
      expect(find.text('Signal -61 dBm'), findsOneWidget);
      expect(find.text('Scanning…'), findsOneWidget);

      await connection.finishScan();
      await tester.pumpAndSettle();
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('BaskoBiteTracker'), findsOneWidget);
    });

    testWidgets('tapping a result connects to it', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('BaskoBiteTracker'));
      await tester.pumpAndSettle();
      expect(connection.connectedId, 'AA:BB');
      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('says when nothing was found', (tester) async {
      connection.found = const [];
      await pumpPage(tester);
      expect(find.textContaining('No bracelet found'), findsOneWidget);
    });

    testWidgets('explains a denied permission', (tester) async {
      connection.scanError =
          const BraceletException(BraceletError.permissionDenied);
      await pumpPage(tester);
      expect(find.textContaining('Nearby devices permission'), findsOneWidget);
    });

    testWidgets('asks for Bluetooth to be turned on', (tester) async {
      connection.scanError = const BraceletException(BraceletError.bluetoothOff);
      await pumpPage(tester);
      expect(find.textContaining('Bluetooth is off'), findsOneWidget);
    });

    testWidgets('explains a failed connection', (tester) async {
      connection.connectError =
          const BraceletException(BraceletError.connectionFailed);
      await pumpPage(tester);
      await tester.tap(find.text('BaskoBiteTracker'));
      await tester.pumpAndSettle();
      expect(find.text('Disconnected'), findsOneWidget);
      expect(find.textContaining("Couldn't connect"), findsOneWidget);
    });
  });

  group('connected', () {
    testWidgets('shows everything the bracelet reports, live', (tester) async {
      await pumpPage(tester);
      await connect(tester);
      connection
        ..emitBattery(87)
        ..emitCharging(false)
        ..emitStatus(const BraceletStatus(
          uptime: Duration(hours: 1, minutes: 12, seconds: 5),
          resetReason: ResetReason.lockup,
        ));
      await tester.pumpAndSettle();

      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('BaskoBiteTracker'), findsOneWidget);
      expect(find.text('87 %'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(find.text('1 h 12 min'), findsOneWidget);
      expect(find.text('CPU fault'), findsOneWidget);
      expect(find.text('Seeed Studio'), findsOneWidget);
      expect(find.text('XIAO nRF52840 Sense'), findsOneWidget);

      connection
        ..emitBattery(86)
        ..emitCharging(true);
      await tester.pumpAndSettle();
      expect(find.text('86 %'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
    });

    testWidgets('disconnect returns to the scan view', (tester) async {
      await pumpPage(tester);
      await connect(tester);
      await tester.tap(find.text('Disconnect'));
      await tester.pumpAndSettle();
      expect(find.text('Disconnected'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
    });

    testWidgets('shut down asks first, then powers the bracelet off',
        (tester) async {
      final shutDownButton = find.widgetWithText(FilledButton, 'Shut down');
      await pumpPage(tester);
      await connect(tester);

      await tester.tap(shutDownButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(connection.shutdownCount, 0);
      expect(find.text('Connected'), findsOneWidget);

      await tester.tap(shutDownButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Shut down'));
      await tester.pumpAndSettle();
      expect(connection.shutdownCount, 1);
      expect(find.text('Disconnected'), findsOneWidget);
    });

    testWidgets('an unexpected drop shows as disconnected', (tester) async {
      await pumpPage(tester);
      await connect(tester);
      connection.dropLink();
      await tester.pumpAndSettle();
      expect(find.text('Disconnected'), findsOneWidget);
      expect(find.text('The bracelet disconnected.'), findsOneWidget);
    });
  });

  group('formatUptime', () {
    test('uses the two largest units', () {
      expect(formatUptime(const Duration(seconds: 45)), '45 s');
      expect(formatUptime(const Duration(minutes: 12, seconds: 3)), '12 min');
      expect(formatUptime(const Duration(hours: 1, minutes: 12)), '1 h 12 min');
      expect(formatUptime(const Duration(days: 2, hours: 3, minutes: 9)),
          '2 d 3 h');
    });
  });
}
