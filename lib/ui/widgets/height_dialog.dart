import 'package:flutter/material.dart';
import 'package:food_locker/core/units.dart';

/// Captures a height, in the system the user reads the rest of the app in.
/// Pops the height in centimetres, or null when it is dismissed.
///
/// Imperial takes feet and inches as two fields because nobody types their
/// height as a decimal number of feet.
class HeightDialog extends StatefulWidget {
  /// Rejects typos like a stray decimal point while still admitting every real
  /// human height.
  static const double minHeightCm = 50;
  static const double maxHeightCm = 272;

  static const Key centimetresFieldKey = Key('height-centimetres-field');
  static const Key feetFieldKey = Key('height-feet-field');
  static const Key inchesFieldKey = Key('height-inches-field');

  final double? initialHeightCm;
  final MeasurementSystem system;

  const HeightDialog({
    super.key,
    required this.initialHeightCm,
    required this.system,
  });

  @override
  State<HeightDialog> createState() => _HeightDialogState();
}

class _HeightDialogState extends State<HeightDialog> {
  final TextEditingController _centimetresController = TextEditingController();
  final TextEditingController _feetController = TextEditingController();
  final TextEditingController _inchesController = TextEditingController();

  late final String _initialCentimetresText;
  late final String _initialFeetText;
  late final String _initialInchesText;

  String? _error;

  @override
  void initState() {
    super.initState();
    final height = widget.initialHeightCm;
    if (height != null) {
      _centimetresController.text = formatLengthValue(height);
      final split = roundedFeetInches(height, 1);
      _feetController.text = '${split.feet}';
      _inchesController.text = formatLengthValue(split.inches);
    }
    _initialCentimetresText = _centimetresController.text;
    _initialFeetText = _feetController.text;
    _initialInchesText = _inchesController.text;
  }

  @override
  void dispose() {
    _centimetresController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  bool get _isMetric => widget.system == MeasurementSystem.metric;

  /// Whether every field still holds exactly what it was opened with. A
  /// cm → ft/in → cm round trip is lossy, so an untouched dialog returns the
  /// stored value rather than a re-derived one.
  bool get _untouched {
    if (_isMetric) {
      return _centimetresController.text == _initialCentimetresText;
    }
    return _feetController.text == _initialFeetText &&
        _inchesController.text == _initialInchesText;
  }

  void _submit() {
    final stored = widget.initialHeightCm;
    if (stored != null && _untouched) {
      Navigator.of(context).pop(stored);
      return;
    }

    final parsed = _isMetric ? _metricHeightCm() : _imperialHeightCm();
    if (parsed == null) {
      setState(() {});
      return;
    }

    Navigator.of(context).pop(parsed);
  }

  /// The entered height in centimetres, or null with [_error] set to a message
  /// phrased in the unit that was actually typed.
  double? _metricHeightCm() {
    final centimetres = _parseNumber(_centimetresController.text);
    if (centimetres == null) {
      _error = 'Enter your height in centimetres';
      return null;
    }
    if (!_isPlausible(centimetres)) {
      _error = 'Enter a height between '
          '${formatLengthValue(HeightDialog.minHeightCm)} and '
          '${formatLengthValue(HeightDialog.maxHeightCm)} cm';
      return null;
    }
    _error = null;
    return centimetres;
  }

  double? _imperialHeightCm() {
    final feet = int.tryParse(_feetController.text.trim());
    // An empty inches field reads as a round number of feet rather than an
    // error, so "6 feet" can be typed as one number.
    final inches = _inchesController.text.trim().isEmpty
        ? 0.0
        : _parseNumber(_inchesController.text);

    if (feet == null || inches == null || feet < 0 || inches < 0) {
      _error = 'Enter your height in feet and inches';
      return null;
    }
    // A silent roll-over into the next foot would store a height nobody typed.
    if (inches >= inchesPerFoot) {
      _error = 'Inches must be less than $inchesPerFoot';
      return null;
    }

    final centimetres = feetInchesToCentimetres(feet, inches);
    if (!_isPlausible(centimetres)) {
      _error = 'Enter a height between '
          '${formatHeight(HeightDialog.minHeightCm, MeasurementSystem.imperial)}'
          ' and '
          '${formatHeight(HeightDialog.maxHeightCm, MeasurementSystem.imperial)}';
      return null;
    }
    _error = null;
    return centimetres;
  }

  bool _isPlausible(double centimetres) =>
      centimetres >= HeightDialog.minHeightCm &&
      centimetres <= HeightDialog.maxHeightCm;

  double? _parseNumber(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Height'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isMetric) _metricField() else _imperialFields(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
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

  Widget _metricField() {
    return TextField(
      key: HeightDialog.centimetresFieldKey,
      controller: _centimetresController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Height (cm)',
        hintText: 'e.g. 178',
        border: OutlineInputBorder(),
      ),
      autofocus: true,
      onSubmitted: (_) => _submit(),
    );
  }

  Widget _imperialFields() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: HeightDialog.feetFieldKey,
            controller: _feetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Feet',
              hintText: 'e.g. 5',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            key: HeightDialog.inchesFieldKey,
            controller: _inchesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Inches',
              hintText: 'e.g. 10',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
      ],
    );
  }
}
