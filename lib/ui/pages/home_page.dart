import 'package:flutter/material.dart';
import 'package:food_locker/core/date_range.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/ui/widgets/add_weight_dialog.dart';
import 'package:food_locker/ui/widgets/app_version_label.dart';
import 'package:food_locker/ui/widgets/history_range_selector.dart';
import 'package:food_locker/ui/widgets/weight_history_tile.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weightManager = context.watch<WeightManager>();
    final history = weightManager.history;
    final range = weightManager.historyRange;

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Latest ${range.span} of Weight',
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
          _buildHistorySection(
            history,
            range: range,
            storeIsEmpty: !weightManager.hasAnyWeights,
          ),
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

  Widget _buildHistorySection(
    List<Weight> history, {
    required DateRange range,
    required bool storeIsEmpty,
  }) {
    if (history.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
          child: Center(
            child: Text(
              storeIsEmpty
                  ? 'No weight entries yet.\nTap "Log Weight" above to get started!'
                  : 'No weight entries in the last ${range.span.toLowerCase()}.\n'
                        'Tap "Log Weight" above to add one.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = history[index];
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
        childCount: history.length,
      ),
    );
  }
}

