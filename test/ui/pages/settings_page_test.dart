import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/settings/data/serialization_service.dart';
import 'package:food_locker/ui/pages/settings_page.dart';
import 'package:provider/provider.dart';

/// Import feedback on [SettingsPage]: the restore reports itself while it runs,
/// and only a real import reports success.
void main() {
  Future<void> pumpPage(WidgetTester tester, SerializationService service) {
    return tester.pumpWidget(
      MaterialApp(
        home: Provider<SerializationService>.value(
          value: service,
          child: const SettingsPage(),
        ),
      ),
    );
  }

  testWidgets('shows a progress toast while restoring, then the success toast',
      (tester) async {
    final service = _FakeSerializationService();
    await pumpPage(tester, service);

    await tester.tap(find.text('Import Data'));
    await tester.pump();

    expect(find.text('Importing data...'), findsOneWidget);
    expect(find.text('Data imported successfully'), findsNothing);

    service.finishRestore();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('Importing data...'), findsNothing);
    expect(find.text('Data imported successfully'), findsOneWidget);
  });

  testWidgets('reports nothing when the file picker is dismissed',
      (tester) async {
    final service = _FakeSerializationService(cancelled: true);
    await pumpPage(tester, service);

    await tester.tap(find.text('Import Data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('Importing data...'), findsNothing);
    expect(find.text('Data imported successfully'), findsNothing);
  });

  testWidgets('replaces the progress toast with the failure toast',
      (tester) async {
    final service = _FakeSerializationService();
    await pumpPage(tester, service);

    await tester.tap(find.text('Import Data'));
    await tester.pump();

    expect(find.text('Importing data...'), findsOneWidget);

    service.failRestore('boom');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('Importing data...'), findsNothing);
    expect(find.textContaining('Import failed'), findsOneWidget);
  });
}

/// Stands in for the real import so the page's feedback can be driven without a
/// file picker: [finishRestore] / [failRestore] decide when — and how — the
/// restore ends.
class _FakeSerializationService extends SerializationService {
  _FakeSerializationService({this.cancelled = false});

  final bool cancelled;
  final _restore = Completer<void>();

  void finishRestore() => _restore.complete();

  void failRestore(String message) => _restore.completeError(message);

  @override
  Future<bool> importData(BuildContext context, {VoidCallback? onRestoreStart}) async {
    if (cancelled) return false;
    onRestoreStart?.call();
    await _restore.future;
    return true;
  }
}
