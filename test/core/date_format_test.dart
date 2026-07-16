import 'package:flutter_test/flutter_test.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The numeric fields a formatted date carries, in render order and with any
/// locale zero-padding stripped — so we assert field *order* without depending
/// on whether a locale pads (`14/07` vs `14/7`).
List<int> _fields(String formatted) => formatted
    .split(RegExp(r'\D+'))
    .where((part) => part.isNotEmpty)
    .map(int.parse)
    .toList();

void main() {
  setUpAll(initializeDateFormatting);

  final date = DateTime(2026, 7, 14);

  test('shortDate renders month/day in the locale field order', () {
    expect(_fields(shortDate(date, 'en_US')), [7, 14]); // 7/14
    expect(_fields(shortDate(date, 'en_GB')), [14, 7]); // 14/7
  });

  test('fullDate renders year/month/day in the locale field order', () {
    expect(_fields(fullDate(date, 'en_US')), [7, 14, 2026]); // 7/14/2026
    expect(_fields(fullDate(date, 'en_GB')), [14, 7, 2026]); // 14/7/2026
  });
}
