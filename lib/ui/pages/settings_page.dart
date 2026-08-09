import 'package:flutter/material.dart';
import 'package:food_locker/features/settings/data/serialization_service.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _importing = false;

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
                  enabled: !_importing,
                  leading: Icon(Icons.download, color: theme.colorScheme.primary),
                  title: const Text('Export Data', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Save your weight history data into a zip file.'),
                  onTap: () async {
                    try {
                      await context.read<SerializationService>().exportData(context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data exported successfully')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  enabled: !_importing,
                  leading: Icon(Icons.upload, color: theme.colorScheme.primary),
                  title: const Text('Import Data', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Restore your weight history data from a zip file.'),
                  onTap: _importData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importData() async {
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<SerializationService>();
    var progressShown = false;

    try {
      final imported = await service.importData(
        context,
        onRestoreStart: () {
          if (!mounted) return;
          progressShown = true;
          setState(() => _importing = true);
          messenger.showSnackBar(_importingSnackBar());
        },
      );
      if (progressShown) messenger.removeCurrentSnackBar();
      // A dismissed file picker imported nothing, so it gets no toast at all.
      if (imported) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Data imported successfully')),
        );
      }
    } catch (e) {
      if (progressShown) messenger.removeCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  /// Stays up until [_importData] removes it, since the restore has no
  /// predictable duration.
  SnackBar _importingSnackBar() {
    return SnackBar(
      duration: const Duration(days: 1),
      content: Row(
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
          const Text('Importing data...'),
        ],
      ),
    );
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
