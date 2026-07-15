import 'package:flutter/foundation.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';

/// Per-screen state for the Bite Analytics page.
///
/// Created from the injected [BiteRepository] when the page opens and loaded
/// once in `initState`. It holds the async-loaded results behind an
/// [isLoading] flag so the screen can show a spinner while the store is read,
/// keeping analytics work off the main Bite screen's hot path and leaving a
/// clean seam for a later window selector or day picker to drive re-loads.
///
/// It establishes whether the log holds any bite at all, which decides the
/// screen's global empty state.
class BiteAnalyticsController extends ChangeNotifier {
  BiteAnalyticsController(BiteRepository repository)
    : _repository = repository,
      _analytics = BiteAnalytics(repository);

  final BiteRepository _repository;
  final BiteAnalytics _analytics;

  /// The chart's window: the [dailyBitesWindow]-day span ending today.
  static const int dailyBitesWindow = 30;

  bool _isLoading = true;

  /// Whether the initial load is still in flight.
  bool get isLoading => _isLoading;

  bool _hasAnyBites = false;

  /// Whether the bite log holds any bite at all. When false the screen shows a
  /// global empty state instead of empty cards.
  bool get hasAnyBites => _hasAnyBites;

  List<DailyBiteCount> _dailyCounts = const [];

  /// Bites per day over the last [dailyBitesWindow] days, one entry per day
  /// that had bites — the daily-bites chart's data.
  List<DailyBiteCount> get dailyCounts => _dailyCounts;

  /// Loads the analytics for the screen, notifying at the start and end so the
  /// spinner shows while the store is read.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _hasAnyBites = await _repository.lastBite() != null;
    final now = DateTime.now();
    final to = DateTime(now.year, now.month, now.day + 1);
    final from = DateTime(now.year, now.month, now.day - (dailyBitesWindow - 1));
    _dailyCounts = await _analytics.dailyCounts(from, to);
    _isLoading = false;
    notifyListeners();
  }
}
