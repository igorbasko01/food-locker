import 'package:flutter/material.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/ui/widgets/add_weight_dialog.dart';
import 'package:food_locker/ui/widgets/app_version_label.dart';
import 'package:food_locker/ui/widgets/longest_streak_banner.dart';
import 'package:food_locker/ui/widgets/streak_banner.dart';
import 'package:food_locker/ui/widgets/weight_history_tile.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weightManager = context.watch<WeightManager>();
    final stats = weightManager.overeatingStats;
    final history = weightManager.history;
    final latest7 = history.take(7).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.monitor_weight_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text('Weight Locker', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Track your progress. Stay clean.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                StreakBanner(stats: stats),
                LongestStreakBanner(stats: stats),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Latest 7 Days of Weight',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddWeightDialog(context, weightManager),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Log Weight'),
                  ),
                ],
              ),
            ),
          ),
          _buildHistorySection(latest7, history),
          const SliverToBoxAdapter(
            child: AppVersionLabel(),
          ),
        ],
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context, WeightManager manager) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddWeightDialog(
        initialDate: DateTime.now(),
      ),
    );

    if (result != null) {
      final date = result['date'] as DateTime;
      final value = result['value'] as double;
      final unit = result['unit'] as WeightUnit;
      manager.addWeight(date, value, unit: unit);
    }
  }

  Widget _buildHistorySection(List<Weight> latest7, List<Weight> history) {
    if (latest7.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
          child: Center(
            child: Text(
              'No weight entries yet.\nTap "Log Weight" above to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = latest7[index];
          // Compute difference with previous day (which is at index + 1 in sorted descending list)
          double? diff;
          if (index + 1 < history.length) {
            diff = item.value - history[index + 1].value;
          }

          return WeightHistoryTile(
            item: item,
            diff: diff,
          );
        },
        childCount: latest7.length,
      ),
    );
  }
}

