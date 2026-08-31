import 'dart:ui';

import 'package:intl/intl.dart';

/// Locale-aware numeric date formatting for every date the app displays.
///
/// Dates are drawn in the device locale's field order — `7/14` under `en_US`,
/// `14/7` under `en_GB` — as numbers, never month names. Both helpers default to
/// [PlatformDispatcher.instance.locale]; an explicit [locale] override keeps them
/// deterministic under test. Non-`en_US` locales need `initializeDateFormatting()`
/// (called once at startup in `main.dart`).

/// Numeric month/day in [locale] order, for axis labels and stat tiles.
String shortDate(DateTime date, [String? locale]) =>
    DateFormat.Md(locale ?? _deviceLocale).format(date);

/// Numeric year/month/day in [locale] order, the default where space allows.
String fullDate(DateTime date, [String? locale]) =>
    DateFormat.yMd(locale ?? _deviceLocale).format(date);

String get _deviceLocale => PlatformDispatcher.instance.locale.toString();
