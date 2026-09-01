import 'dart:ui';

import 'package:intl/intl.dart';

/// Locale-aware date and time formatting for everything the app displays.
///
/// Dates are drawn in the device locale's field order — `7/14` under `en_US`,
/// `14/7` under `en_GB` — as numbers, never month names, and times follow the
/// locale's clock convention. Every helper defaults to
/// [PlatformDispatcher.instance.locale]; an explicit [locale] override keeps them
/// deterministic under test. Non-`en_US` locales need `initializeDateFormatting()`
/// (called once at startup in `main.dart`).

/// Numeric month/day in [locale] order, for axis labels and stat tiles.
String shortDate(DateTime date, [String? locale]) =>
    DateFormat.Md(locale ?? _deviceLocale).format(date);

/// Numeric year/month/day in [locale] order, the default where space allows.
String fullDate(DateTime date, [String? locale]) =>
    DateFormat.yMd(locale ?? _deviceLocale).format(date);

/// The clock time, 12- or 24-hour as [locale] dictates.
String shortTime(DateTime at, [String? locale]) =>
    DateFormat.jm(locale ?? _deviceLocale).format(at);

String get _deviceLocale => PlatformDispatcher.instance.locale.toString();
