import 'package:flutter/material.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/features/weight/data/weight.dart';

class AddWeightDialog extends StatefulWidget {
  final DateTime initialDate;
  final double? initialWeight;

  const AddWeightDialog({
    super.key,
    required this.initialDate,
    this.initialWeight,
  });

  @override
  State<AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends State<AddWeightDialog> {
  late DateTime _selectedDate;
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    if (widget.initialWeight != null) {
      _weightController.text = widget.initialWeight!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _submit() {
    final weightStr = _weightController.text.replaceAll(',', '.');
    final weight = double.tryParse(weightStr);
    if (weight != null && weight > 0) {
      Navigator.of(context).pop({
        'date': _selectedDate,
        'value': weight,
        'unit': WeightUnit.kilograms,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialWeight == null ? 'Log Weight' : 'Edit Weight'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Date:'),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final newDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (newDate != null) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                  }
                },
                child: Text(fullDate(_selectedDate)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              hintText: 'e.g. 75.5',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        if (widget.initialWeight != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop({'delete': true}),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
