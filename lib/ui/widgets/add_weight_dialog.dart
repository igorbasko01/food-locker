import 'package:flutter/material.dart';
import 'package:food_locker/features/weight/data/weight.dart';

class AddWeightDialog extends StatefulWidget {
  final DateTime initialDate;

  const AddWeightDialog({super.key, required this.initialDate});

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
      title: const Text('Log Weight'),
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
                child: Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
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
