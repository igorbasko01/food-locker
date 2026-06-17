import 'package:flutter/material.dart';
import 'package:food_locker/features/settings/data/serialization_service.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
                  leading: Icon(Icons.upload, color: theme.colorScheme.primary),
                  title: const Text('Import Data', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Restore your weight history data from a zip file.'),
                  onTap: () async {
                    try {
                      await context.read<SerializationService>().importData(context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data imported successfully')),
                        );
                        setState(() {});
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
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
