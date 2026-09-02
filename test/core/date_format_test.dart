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

  test('the WithWeekday variants keep the locale field order', () {
    expect(_fields(shortDateWithWeekday(date, 'en_US')), [7, 14]);
    expect(_fields(shortDateWithWeekday(date, 'en_GB')), [14, 7]);
    expect(_fields(fullDateWithWeekday(date, 'en_US')), [7, 14, 2026]);
    expect(_fields(fullDateWithWeekday(date, 'en_GB')), [14, 7, 2026]);
  });

  test('the WithWeekday variants name the weekday in three letters', () {
    // Narrow weekday names collide (Sunday and Saturday are both `S`), so the
    // abbreviated form is the point of these helpers.
    expect(shortDateWithWeekday(date, 'en_US'), startsWith('Tue'));
    expect(fullDateWithWeekday(date, 'en_US'), startsWith('Tue'));
  });

  test('the numeric variants stay free of the weekday, for chart axes', () {
    expect(shortDate(date, 'en_US'), isNot(contains('Tue')));
    expect(fullDate(date, 'en_US'), isNot(contains('Tue')));
  });

  test('shortTime follows the locale clock convention', () {
    final afternoon = DateTime(2026, 7, 14, 13, 30);

    // en_US is 12-hour with a day period; the separator before it is locale
    // data (a narrow no-break space in current CLDR), so match on the parts.
    expect(shortTime(afternoon, 'en_US'), startsWith('1:30'));
    expect(shortTime(afternoon, 'en_US'), contains('PM'));

    expect(shortTime(afternoon, 'en_GB'), '13:30');
  });
}
