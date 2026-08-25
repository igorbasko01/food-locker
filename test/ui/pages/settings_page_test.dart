import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/features/settings/data/serialization_service.dart';
import 'package:food_locker/ui/pages/settings_page.dart';
import 'package:provider/provider.dart';

/// Backup feedback on [SettingsPage]: work in flight says so, and only work
/// that actually moved data reports success.
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

  /// Long enough for a snackbar to finish animating in or out.
  Future<void> pumpToast(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
  }

  /// Taps Import and answers the confirmation dialog it raises.
  Future<void> tapImport(WidgetTester tester, {required bool confirm}) async {
    await tester.tap(find.text('Import Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(confirm ? 'Replace' : 'Cancel'));
    await tester.pump();
  }

  group('import', () {
    testWidgets('asks before restoring, naming the file it would replace',
        (tester) async {
      final service = _FakeSerializationService();
      await pumpPage(tester, service);

      await tester.tap(find.text('Import Data'));
      await tester.pumpAndSettle();

      expect(find.text('Replace all data?'), findsOneWidget);
      expect(
        find.textContaining(_FakeSerializationService.fileName),
        findsOneWidget,
      );
      // Nothing has started: the restore waits behind the dialog.
      expect(find.text('Importing data...'), findsNothing);
    });

    testWidgets('reports nothing when the confirmation is cancelled',
        (tester) async {
      final service = _FakeSerializationService();
      await pumpPage(tester, service);

      await tapImport(tester, confirm: false);
      await pumpToast(tester);

      expect(find.text('Replace all data?'), findsNothing);
      expect(find.text('Importing data...'), findsNothing);
      expect(find.text('Data imported successfully'), findsNothing);
    });

    testWidgets('shows a progress toast while restoring, then the success toast',
        (tester) async {
      final service = _FakeSerializationService();
      await pumpPage(tester, service);

      await tapImport(tester, confirm: true);

      expect(find.text('Importing data...'), findsOneWidget);
      expect(find.text('Data imported successfully'), findsNothing);

      service.finish();
      await pumpToast(tester);

      expect(find.text('Importing data...'), findsNothing);
      expect(find.text('Data imported successfully'), findsOneWidget);
    });

    testWidgets('reports nothing when the file picker is dismissed',
        (tester) async {
      final service = _FakeSerializationService(cancelled: true);
      await pumpPage(tester, service);

      await tester.tap(find.text('Import Data'));
      await pumpToast(tester);

      expect(find.text('Importing data...'), findsNothing);
      expect(find.text('Data imported successfully'), findsNothing);
    });

    testWidgets('replaces the progress toast with the failure toast',
        (tester) async {
      final service = _FakeSerializationService();
      await pumpPage(tester, service);

      await tapImport(tester, confirm: true);

      expect(find.text('Importing data...'), findsOneWidget);

      service.fail('boom');
      await pumpToast(tester);

      expect(find.text('Importing data...'), findsNothing);
      expect(find.textContaining('Import failed'), findsOneWidget);
    });
  });

  group('export', () {
    testWidgets('shows a progress toast while exporting, then the success toast',
        (tester) async {
      final service = _FakeSerializationService();
      await pumpPage(tester, service);

      await tester.tap(find.text('Export Data'));
      await tester.pump();

      expect(find.text('Exporting data...'), findsOneWidget);
      expect(find.text('Data exported successfully'), findsNothing);

      service.finish();
      await pumpToast(tester);

      expect(find.text('Exporting data...'), findsNothing);
      expect(find.text('Data exported successfully'), findsOneWidget);
    });

    testWidgets('reports an empty export rather than success', (tester) async {
      final service = _FakeSerializationService(empty: true);
      await pumpPage(tester, service);

      await tester.tap(find.text('Export Data'));
      service.finish();
      await pumpToast(tester);

      expect(find.text('Data exported successfully'), findsNothing);
      expect(find.text('No data to export'), findsOneWidget);
    });
  });
}

/// Replaces the file picker, the restore, and the share sheet, holding the work
/// open until [finish] or [fail] ends it.
class _FakeSerializationService extends SerializationService {
  _FakeSerializationService({this.cancelled = false, this.empty = false});

  /// Import only: the user dismissed the file picker.
  final bool cancelled;

  /// Export only: both stores were empty.
  final bool empty;

  /// The name the picker resolved, as handed to the confirmation.
  static const fileName = 'food_locker_20260101120000.zip';

  final _work = Completer<void>();

  void finish() => _work.complete();

  void fail(String message) => _work.completeError(message);

  @override
  Future<bool> importData(
    BuildContext context, {
    ConfirmRestore? onConfirm,
    VoidCallback? onRestoreStart,
  }) async {
    if (cancelled) return false;
    if (onConfirm != null && !await onConfirm(fileName)) return false;
    onRestoreStart?.call();
    await _work.future;
    return true;
  }

  @override
  Future<bool> exportData(BuildContext context, {VoidCallback? onShareReady}) async {
    await _work.future;
    if (empty) return false;
    onShareReady?.call();
    return true;
  }
}
