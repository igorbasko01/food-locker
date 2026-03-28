import 'package:flutter/material.dart';

class DayDateText extends StatelessWidget {
  final DateTime date;
  final TextStyle? style;

  const DayDateText({
    super.key,
    required this.date,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDate(date),
      style: style,
    );
  }

  static String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Optional: Expose the formatting logic if needed elsewhere without the widget.
  static String format(DateTime date) => _formatDate(date);
}
