import 'package:flutter/material.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/ui/widgets/add_weight_dialog.dart';
import 'package:food_locker/ui/widgets/weight_chart.dart';
import 'package:provider/provider.dart';

class WeightPage extends StatelessWidget {
  const WeightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeightManager>(
      builder: (context, weightManager, child) {
        final history = weightManager.history;

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddWeightDialog(context, weightManager),
            child: const Icon(Icons.add),
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: Card(
                      elevation: 4,
                      child: WeightChart(weights: history),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (history.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('No weight entries yet. Tap + to log your weight.'),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = history[index];
                      // Format date nicely
                      final dateStr = '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';

                      return Dismissible(
                        key: ValueKey(item.date),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          weightManager.deleteWeight(item.date);
                        },
                        child: ListTile(
                          title: Text(
                            dateStr,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item.value.toStringAsFixed(1)} kg',
                                style: const TextStyle(fontSize: 16.0),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ],
                          ),
                          onTap: () => _showAddWeightDialog(context, weightManager, weight: item),
                        ),
                      );
                    },
                    childCount: history.length,
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80), // Padding for FAB
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddWeightDialog(BuildContext context, WeightManager manager, {Weight? weight}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddWeightDialog(
        initialDate: weight?.date ?? DateTime.now(),
        initialWeight: weight?.value,
      ),
    );

    if (result != null) {
      if (result['delete'] == true && weight != null) {
        manager.deleteWeight(weight.date);
        return;
      }

      final date = result['date'] as DateTime;
      final value = result['value'] as double;
      final unit = result['unit'] as WeightUnit;
      
      if (weight != null) {
        manager.updateWeight(weight.date, date, value, unit: unit);
      } else {
        manager.addWeight(date, value, unit: unit);
      }
    }
  }
}
