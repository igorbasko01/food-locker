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

  /// The chart's window, and the span the 30-day average and max cover: the
  /// [dailyBitesWindow]-day span ending today.
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

  double _averageLast30 = 0;

  /// Mean daily bites over the last [dailyBitesWindow] days, counting only days
  /// at or above [BiteAnalytics.minBitesForAverage]. 0 when no day qualifies.
  double get averageLast30 => _averageLast30;

  double _averageLastYear = 0;

  /// Mean daily bites over the last year, on the same qualifying-days rule as
  /// [averageLast30]. 0 when no day qualifies.
  double get averageLastYear => _averageLastYear;

  DailyBiteCount? _maxLast30;

  /// The highest-bite day in the last [dailyBitesWindow] days, or null when the
  /// window holds no bites — the max stat tile's value and its date.
  DailyBiteCount? get maxLast30 => _maxLast30;

  int _mealsToday = 0;

  /// The number of meals logged today — clusters that reached
  /// [BiteAnalytics.minMealBites]. 0 when today has no qualifying meal.
  int get mealsToday => _mealsToday;

  double _averageMealsLast30 = 0;

  /// Mean meals per day over the last [dailyBitesWindow] days, across only the
  /// days that had at least one bite. 0 when the window holds no bites.
  double get averageMealsLast30 => _averageMealsLast30;

  DayMealBreakdown _breakdownToday = DayMealBreakdown(
    day: DateTime.fromMillisecondsSinceEpoch(0),
    meals: const [],
    snackBites: 0,
  );

  /// Today split into its meals and its snack total — the meal-breakdown card's
  /// data. Empty (no meals, no snack bites) until today has a bite.
  DayMealBreakdown get breakdownToday => _breakdownToday;

  /// Loads the analytics for the screen, notifying at the start and end so the
  /// spinner shows while the store is read.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _hasAnyBites = await _repository.lastBite() != null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final to = DateTime(now.year, now.month, now.day + 1);
    final from30 = DateTime(
      now.year,
      now.month,
      now.day - (dailyBitesWindow - 1),
    );
    final fromYear = DateTime(now.year - 1, now.month, now.day + 1);
    _dailyCounts = await _analytics.dailyCounts(from30, to);
    _averageLast30 = await _analytics.averagePerDay(from30, to);
    _maxLast30 = await _analytics.maxDay(from30, to);
    _averageLastYear = await _analytics.averagePerDay(fromYear, to);
    _breakdownToday = await _analytics.breakdownForDay(today);
    _mealsToday = _breakdownToday.meals.length;
    _averageMealsLast30 = await _analytics.averageMealsPerDay(from30, to);
    _isLoading = false;
    notifyListeners();
  }
}
