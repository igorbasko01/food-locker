import 'package:flutter/material.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/core/units.dart';
import 'package:food_locker/features/settings/data/settings_manager.dart';
import 'package:food_locker/features/weight/data/bmi.dart';
import 'package:food_locker/features/weight/data/weekly_weight_change.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';
import 'package:food_locker/ui/widgets/add_weight_dialog.dart';
import 'package:food_locker/ui/widgets/bmi_scale.dart';
import 'package:food_locker/ui/widgets/height_dialog.dart';
import 'package:food_locker/ui/widgets/history_range_selector.dart';
import 'package:food_locker/ui/widgets/stat_tile.dart';
import 'package:food_locker/ui/widgets/weight_chart.dart';
import 'package:provider/provider.dart';

class WeightPage extends StatelessWidget {
  const WeightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeightManager>(
      builder: (context, weightManager, child) {
        final history = weightManager.history;
        final range = weightManager.historyRange;
        final system = context.watch<SettingsManager>().measurementSystem;

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                _showAddWeightDialog(context, weightManager, system),
            child: const Icon(Icons.add),
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                  child: _CurrentWeight(
                    entry: weightManager.latestEntry,
                    system: system,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: Card(
                      elevation: 4,
                      child: WeightChart(weights: history, system: system),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildWeeklyChangeTile(
                        context,
                        weightManager.weeklyChange,
                        system,
                      ),
                      const SizedBox(width: 8),
                      _buildTrendTile(
                        context,
                        weightManager.trendPerWeek,
                        system,
                      ),
                      const SizedBox(width: 8),
                      _buildVsLowTile(
                        context,
                        weightManager.changeFromLowest,
                        weightManager.lowestEntry,
                        system,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0),
                  child: _Bmi(entry: weightManager.latestEntry),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      HistoryRangeSelector(
                        selected: range,
                        onSelected: weightManager.selectHistoryRange,
                      ),
                    ],
                  ),
                ),
              ),
              if (history.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No weight entries in the last ${range.span.toLowerCase()}. '
                        'Tap + to log your weight.',
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = history[index];
                      final dateStr = fullDateWithWeekday(item.date);

                      return ListTile(
                        key: ValueKey(item.date),
                        title: Text(
                          dateStr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              system.formatWeight(item.value),
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
                        onTap: () => _showAddWeightDialog(
                          context,
                          weightManager,
                          system,
                          weight: item,
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

  void _showAddWeightDialog(
    BuildContext context,
    WeightManager manager,
    MeasurementSystem system, {
    Weight? weight,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddWeightDialog(
        initialDate: weight?.date ?? DateTime.now(),
        initialWeight: weight?.value,
        system: system,
      ),
    );

    if (result != null) {
      if (result['delete'] == true && weight != null) {
        manager.deleteWeight(weight.date);
        return;
      }

      final date = result['date'] as DateTime;
      final value = result['value'] as double;

      if (weight != null) {
        manager.updateWeight(weight.date, date, value);
      } else {
        manager.addWeight(date, value);
      }
    }
  }

  Widget _buildWeeklyChangeTile(
    BuildContext context,
    WeeklyWeightChange week,
    MeasurementSystem system,
  ) {
    final change = week.delta;
    if (change == null) return _missingStatTile('Weekly change');

    final rounded = _roundTo(system.weightFromKilograms(change), 1);
    return Expanded(
      child: StatTile(
        label: 'Weekly change',
        value: '${_signed(rounded, 1)} ${system.weightSymbol}',
        subLabel: _weeklyChangeWeeks(week),
        valueColor: _directionColor(context, rounded),
        icon: _directionIcon(rounded),
      ),
    );
  }

  Widget _buildTrendTile(
    BuildContext context,
    double? perWeek,
    MeasurementSystem system,
  ) {
    if (perWeek == null) return _missingStatTile('30-day trend');

    final shown = system.weightFromKilograms(perWeek);
    final rounded = _roundTo(shown, 2);
    final perMonth = _roundTo(shown * 30 / 7, 1);
    return Expanded(
      child: StatTile(
        label: '30-day trend',
        value: '${_signed(rounded, 2)} ${system.weightSymbol}/wk',
        subLabel: '≈ ${_signed(perMonth, 1)} ${system.weightSymbol}/month',
        valueColor: _directionColor(context, rounded),
        icon: _directionIcon(rounded),
      ),
    );
  }

  Widget _buildVsLowTile(
    BuildContext context,
    double? change,
    Weight? lowest,
    MeasurementSystem system,
  ) {
    if (change == null || lowest == null) {
      return _missingStatTile('Vs. low');
    }

    final rounded = _roundTo(system.weightFromKilograms(change), 1);
    final low = system.weightFromKilograms(lowest.value).toStringAsFixed(1);
    return Expanded(
      child: StatTile(
        label: 'Vs. low',
        value: '${_signed(rounded, 1)} ${system.weightSymbol}',
        subLabel: 'low $low on ${shortDate(lowest.date)}',
        // Never negative, so signed green/red would leave this tile
        // permanently red. Standing on the low earns the trophy instead.
        valueColor: Theme.of(context).colorScheme.onSurfaceVariant,
        icon: rounded == 0 ? Icons.emoji_events : null,
      ),
    );
  }
}

/// The latest weigh-in, dated so an old reading is never mistaken for today's.
class _CurrentWeight extends StatelessWidget {
  const _CurrentWeight({required this.entry, required this.system});

  final Weight? entry;
  final MeasurementSystem system;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = entry;
    final value = current == null
        ? '--'
        : system.formatWeight(current.value);
    final caption = current == null
        ? 'No weigh-ins yet'
        : 'as of ${fullDateWithWeekday(current.date)}';

    return Semantics(
      label: 'Current weight: $value, $caption',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The latest weigh-in read against the stored height, on the banded BMI scale.
///
/// Neither input is ever guessed: a missing height asks for one, and a store
/// with no weigh-in yet says so.
class _Bmi extends StatelessWidget {
  const _Bmi({required this.entry});

  final Weight? entry;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsManager>();
    final current = entry;

    if (current == null) {
      return _note(context, 'Log a weigh-in to see your BMI.');
    }

    final heightCm = settings.heightCm;
    if (heightCm == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _note(context, 'Set your height to see your BMI.'),
          TextButton(
            onPressed: () => _editHeight(context),
            child: const Text('Set height'),
          ),
        ],
      );
    }

    return BmiScale(
      bmi: bodyMassIndex(kilograms: current.value, heightCm: heightCm),
    );
  }

  /// The same editor the Settings tab opens, in the same system, so the height
  /// is answered once and read the same way wherever it is entered.
  Future<void> _editHeight(BuildContext context) async {
    final settings = context.read<SettingsManager>();

    final heightCm = await showDialog<double>(
      context: context,
      builder: (context) => HeightDialog(
        initialHeightCm: settings.heightCm,
        system: settings.measurementSystem,
      ),
    );

    if (heightCm != null) await settings.setHeightCm(heightCm);
  }

  Widget _note(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// The two weeks the weekly-change figure came from, each named by the Sunday
/// it opens.
///
/// The comparison skips the week in progress, so an unlabelled tile reads as
/// this week against last when it is up to six days behind. What each week's
/// mean rests on is the heatmap cell's story, not the tile's.
String _weeklyChangeWeeks(WeeklyWeightChange week) =>
    '${shortDate(week.weekStart)} vs ${shortDate(week.previousWeekStart)}';

/// The tile a statistic the store has too little for falls back to.
Widget _missingStatTile(String label) =>
    Expanded(child: StatTile(label: label, value: '--'));

/// [value] rounded to what the tile will print, so its sign, colour, and arrow
/// agree with the digits — a -0.04 kg week reads as flat, not as a loss.
double _roundTo(double value, int decimals) =>
    double.parse(value.toStringAsFixed(decimals));

String _signed(double value, int decimals) {
  final magnitude = value.abs().toStringAsFixed(decimals);
  if (value > 0) return '+$magnitude';
  if (value < 0) return '-$magnitude';
  return magnitude;
}

/// Down is green and up is the error colour, matching the history rows'
/// change indicator so the whole tab reads the same way.
Color _directionColor(BuildContext context, double value) {
  final scheme = Theme.of(context).colorScheme;
  if (value > 0) return scheme.error;
  if (value < 0) return Colors.green;
  return scheme.outline;
}

IconData _directionIcon(double value) {
  if (value > 0) return Icons.arrow_upward_rounded;
  if (value < 0) return Icons.arrow_downward_rounded;
  return Icons.remove_rounded;
}
