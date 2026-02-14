import 'package:flutter/material.dart';
import 'package:food_locker/features/food/data/food_config.dart';
import 'package:food_locker/features/food/data/food_config_repository.dart';
import 'package:food_locker/features/food/data/food_type.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _addConfig(String name, FoodType type) {
    final repo = context.read<FoodConfigRepository>();
    repo.add(FoodConfig(name: name, type: type));
    setState(() {});
  }

  void _removeConfig(FoodConfig config) {
    final repo = context.read<FoodConfigRepository>();
    repo.remove(config);
    setState(() {});
  }

  Future<void> _showAddDialog() async {
    String name = '';
    FoodType type = FoodType.meal;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Food Config'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (value) => name = value,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButton<FoodType>(
                  value: type,
                  isExpanded: true,
                  items: FoodType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => type = value);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (name.isNotEmpty) {
                    _addConfig(name, type);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FoodConfigRepository>();
    final meals = repo.getFoodConfigsByType(FoodType.meal);
    final snacks = repo.getFoodConfigsByType(FoodType.snack);
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(theme, 'Meals'),
          if (meals.isEmpty) _buildEmptyState('No meals defined'),
          ...meals.map((c) => _buildConfigTile(c)),
          const SizedBox(height: 24),
          _buildHeader(theme, 'Snacks'),
          if (snacks.isEmpty) _buildEmptyState('No snacks defined'),
          ...snacks.map((c) => _buildConfigTile(c)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        message,
        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      ),
    );
  }

  Widget _buildConfigTile(FoodConfig config) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(config.name),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _removeConfig(config),
        ),
      ),
    );
  }
}
