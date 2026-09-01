import 'dart:ui';

import 'package:intl/intl.dart';

/// Locale-aware date and time formatting for everything the app displays.
///
/// Dates are drawn in the device locale's field order — `7/14` under `en_US`,
/// `14/7` under `en_GB` — with numeric months, never month names, and times
/// follow the locale's clock convention. The `WithWeekday` variants add the
/// abbreviated weekday name, placed where the locale puts it. Every helper
/// defaults to [PlatformDispatcher.instance.locale]; an explicit [locale]
/// override keeps them deterministic under test. Non-`en_US` locales need
/// `initializeDateFormatting()` (called once at startup in `main.dart`).

/// Numeric month/day in [locale] order, for chart axis labels.
String shortDate(DateTime date, [String? locale]) =>
    DateFormat.Md(locale ?? _deviceLocale).format(date);

/// Numeric year/month/day in [locale] order, without the weekday.
String fullDate(DateTime date, [String? locale]) =>
    DateFormat.yMd(locale ?? _deviceLocale).format(date);

/// [shortDate] carrying the abbreviated weekday, e.g. `Tue, 7/14`.
String shortDateWithWeekday(DateTime date, [String? locale]) =>
    DateFormat.MEd(locale ?? _deviceLocale).format(date);

/// [fullDate] carrying the abbreviated weekday, e.g. `Tue, 7/14/2026`.
///
/// The default where a date is read; [shortDate] and [fullDate] stay for chart
/// axes and anywhere else too tight for the weekday.
String fullDateWithWeekday(DateTime date, [String? locale]) =>
    DateFormat.yMEd(locale ?? _deviceLocale).format(date);

/// The clock time, 12- or 24-hour as [locale] dictates.
String shortTime(DateTime at, [String? locale]) =>
    DateFormat.jm(locale ?? _deviceLocale).format(at);

String get _deviceLocale => PlatformDispatcher.instance.locale.toString();
