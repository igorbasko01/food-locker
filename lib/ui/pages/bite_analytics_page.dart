import 'package:flutter/material.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/bite/data/bite_analytics_controller.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/ui/widgets/daily_bites_chart.dart';
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
          return ListView(
            children: [_DailyBitesCard(counts: _controller.dailyCounts)],
          );
        },
      ),
    );
  }
}

/// The daily-bites chart, framed in a titled card with a fixed height so the
/// bars have room without the surrounding [ListView] collapsing them.
class _DailyBitesCard extends StatelessWidget {
  const _DailyBitesCard({required this.counts});

  final List<DailyBiteCount> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(16.0),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily bites — last 30 days',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: 240, child: DailyBitesChart(counts: counts)),
          ],
        ),
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
