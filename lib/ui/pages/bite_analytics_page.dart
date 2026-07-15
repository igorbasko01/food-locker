import 'package:flutter/material.dart';
import 'package:food_locker/features/bite/data/bite_analytics_controller.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:provider/provider.dart';

/// The read-only Bite Analytics dashboard, reached from the chart button in the
/// Bite tab's app bar.
///
/// Self-contained: it owns its own [Scaffold]/[AppBar] (with the automatic back
/// arrow) so it does not fight the app shell's shared chrome, and loads its data
/// once through a per-screen [BiteAnalyticsController]. It shows a spinner while
/// loading and a global empty state when no bites have ever been logged.
class BiteAnalyticsPage extends StatefulWidget {
  const BiteAnalyticsPage({super.key});

  @override
  State<BiteAnalyticsPage> createState() => _BiteAnalyticsPageState();
}

class _BiteAnalyticsPageState extends State<BiteAnalyticsPage> {
  late final BiteAnalyticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BiteAnalyticsController(context.read<BiteRepository>())
      ..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bite Analytics')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_controller.hasAnyBites) {
            return const _EmptyAnalytics();
          }
          // Analytics cards render here once there is data to show.
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Shown when the bite log is empty: there is nothing to analyse until bites
/// are logged on the Bite tab.
class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No bites logged yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Log bites on the Bite tab to see your trends here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
