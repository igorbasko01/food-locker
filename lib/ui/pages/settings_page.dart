import 'package:flutter/material.dart';
import 'package:food_locker/features/bite/data/bite_manager.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/settings/data/serialization_service.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(theme, 'Data Management'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  enabled: !_busy,
                  leading: Icon(Icons.download, color: theme.colorScheme.primary),
                  title: const Text('Export Data', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Save your weight history data into a zip file.'),
                  onTap: _exportData,
                ),
                const Divider(height: 1),
                ListTile(
                  enabled: !_busy,
                  leading: Icon(Icons.upload, color: theme.colorScheme.primary),
                  title: const Text('Import Data', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Replace your data with a backup zip file.'),
                  onTap: _importData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildHeader(theme, 'Danger Zone'),
          Card(
            elevation: 0,
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: ListTile(
              enabled: !_busy,
              leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
              title: const Text('Clear All Data', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Permanently delete all weight and bite data.'),
              onTap: _clearAllData,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<SerializationService>();

    setState(() => _busy = true);
    messenger.showSnackBar(_progressSnackBar('Exporting data...'));

    try {
      final exported = await service.exportData(
        context,
        onShareReady: messenger.removeCurrentSnackBar,
      );
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(exported ? 'Data exported successfully' : 'No data to export'),
        ),
      );
    } catch (e) {
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importData() async {
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<SerializationService>();
    final weightManager = context.read<WeightManager>();
    final biteManager = context.read<BiteManager>();
    var progressShown = false;

    try {
      final imported = await service.importData(
        context,
        onConfirm: _confirmImport,
        onRestoreStart: () {
          progressShown = true;
          messenger.showSnackBar(_progressSnackBar('Importing data...'));
          if (mounted) setState(() => _busy = true);
        },
      );
      // Only clear a toast this call put up: a dismissed picker shows none, and
      // removing unconditionally would cut short whatever else is on screen.
      if (progressShown) messenger.removeCurrentSnackBar();
      if (imported) {
        // A restore writes through the repositories, leaving both managers on
        // what they loaded before it. Re-read here rather than leaning on a tab
        // refreshing when it becomes visible.
        await weightManager.refresh();
        await biteManager.refresh();
        messenger.showSnackBar(
          const SnackBar(content: Text('Data imported successfully')),
        );
      }
    } catch (e) {
      if (progressShown) messenger.removeCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// An import replaces what is already stored, so it asks first — and names
  /// the file, since picking the wrong zip is the likely mistake.
  Future<bool> _confirmImport(String fileName) async {
    if (!mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Replace all data?'),
          content: Text(
            'Importing "$fileName" permanently replaces your weight history, '
            'and the bite log and pacing settings when the backup contains '
            'them. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Replace'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _clearAllData() async {
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<SerializationService>();
    final weightRepo = context.read<WeightRepository>();
    final biteRepo = context.read<BiteRepository>();
    final weightManager = context.read<WeightManager>();
    final biteManager = context.read<BiteManager>();

    if (!await _confirmClear() || !mounted) return;

    setState(() => _busy = true);
    messenger.showSnackBar(_progressSnackBar('Clearing data...'));

    try {
      await service.clearAllData(weightRepo, biteRepo);
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('All data cleared')));
    } catch (e) {
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Clear failed: $e')));
    } finally {
      // The clear goes straight through the repositories, so both managers are
      // still serving what they last read. A clear that failed part way still
      // deleted something, so they are re-read either way.
      await weightManager.refresh();
      await biteManager.refresh();
      if (mounted) setState(() => _busy = false);
    }
  }

  /// A clear is unrecoverable, so it asks first and points at the export that
  /// would have made the data recoverable.
  Future<bool> _confirmClear() async {
    if (!mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Clear all data?'),
          content: const Text(
            'This permanently deletes your weight history, the bite log and '
            'your pacing settings. It cannot be undone — export a backup first '
            'if you might want any of it back.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Widget _buildHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Export and restore have no predictable length, so this stays up until the
/// caller removes it. The [Builder] reads the theme from the snackbar's own
/// context, keeping the spinner legible on the inverse-surface background
/// without depending on the page still being mounted.
SnackBar _progressSnackBar(String message) {
  return SnackBar(
    duration: const Duration(days: 1),
    content: Builder(
      builder: (context) => Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
          ),
          const SizedBox(width: 16),
          Text(message),
        ],
      ),
    ),
  );
}
