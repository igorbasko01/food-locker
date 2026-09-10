import 'package:flutter/material.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/core/units.dart';

/// Logs or edits one day's weigh-in, in [system].
///
/// [initialWeight] and the `value` this pops are both kilograms — the system is
/// a display-and-input concern, converted at this boundary and nowhere else.
class AddWeightDialog extends StatefulWidget {
  final DateTime initialDate;
  final double? initialWeight;
  final MeasurementSystem system;

  const AddWeightDialog({
    super.key,
    required this.initialDate,
    this.initialWeight,
    this.system = MeasurementSystem.metric,
  });

  @override
  State<AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends State<AddWeightDialog> {
  late DateTime _selectedDate;
  final TextEditingController _weightController = TextEditingController();

  /// What [initState] prefilled the field with. Converting that back on save
  /// would quantise the stored kilograms — up to ~23 g per save in pounds — so
  /// an untouched field returns the stored value instead of a round trip.
  String _prefilled = '';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    final initialWeight = widget.initialWeight;
    if (initialWeight != null) {
      _prefilled = widget.system
          .weightFromKilograms(initialWeight)
          .toStringAsFixed(1);
      _weightController.text = _prefilled;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _submit() {
    final initialWeight = widget.initialWeight;
    final typed = _weightController.text;
    if (initialWeight != null && typed == _prefilled) {
      Navigator.of(context).pop({
        'date': _selectedDate,
        'value': initialWeight,
      });
      return;
    }

    // Validated as typed, so a rejection is about the number on screen.
    final weight = double.tryParse(typed.replaceAll(',', '.'));
    if (weight != null && weight > 0) {
      Navigator.of(context).pop({
        'date': _selectedDate,
        'value': widget.system.weightToKilograms(weight),
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
                child: Text(fullDateWithWeekday(_selectedDate)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Weight (${widget.system.weightSymbol})',
              hintText: widget.system == MeasurementSystem.imperial
                  ? 'e.g. 165.5'
                  : 'e.g. 75.5',
              border: const OutlineInputBorder(),
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
