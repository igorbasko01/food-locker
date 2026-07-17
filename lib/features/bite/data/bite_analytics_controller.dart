import 'package:flutter/foundation.dart';
import 'package:food_locker/features/bite/data/bite_analytics.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';
import 'package:food_locker/features/weight/data/weight.dart';
import 'package:food_locker/features/weight/data/weight_repository.dart';

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
  BiteAnalyticsController(
    BiteRepository repository,
    WeightRepository weightRepository,
  ) : _repository = repository,
      _weightRepository = weightRepository,
      _analytics = BiteAnalytics(repository);

  final BiteRepository _repository;
  final WeightRepository _weightRepository;
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

  List<Weight> _dailyWeights = const [];

  /// Raw daily weigh-ins over the last [dailyBitesWindow] days, one per day that
  /// was weighed — the weight bars overlaid on the daily-bites chart. Days
  /// without a weigh-in are simply absent (no gap-filling).
  List<Weight> get dailyWeights => _dailyWeights;

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

  double _averageMealsLast30 = 0;

  /// Mean meals per day over the last [dailyBitesWindow] days, across only the
  /// days that had at least one bite. 0 when the window holds no bites.
  double get averageMealsLast30 => _averageMealsLast30;

  double _averageMealSizeLast30 = 0;

  /// Mean bites per meal over the last [dailyBitesWindow] days, across only
  /// qualifying meals (snacks excluded). 0 when the window holds no meal.
  double get averageMealSizeLast30 => _averageMealSizeLast30;

  int _mealsToday = 0;

  DateTime _selectedDay = DateTime.fromMillisecondsSinceEpoch(0);

  /// The calendar day the breakdown card is showing, at local midnight. Seeded
  /// to today by [load] and moved by [selectDay] when a chart bar is tapped.
  DateTime get selectedDay => _selectedDay;

  /// Whether [selectedDay] is today — drives the card's "Back to today"
  /// affordance, shown only while browsing another day.
  bool get isSelectedDayToday {
    final now = DateTime.now();
    return _selectedDay == DateTime(now.year, now.month, now.day);
  }

  DayMealBreakdown _selectedBreakdown = DayMealBreakdown(
    day: DateTime.fromMillisecondsSinceEpoch(0),
    meals: const [],
    snackBites: 0,
  );

  /// [selectedDay] split into its meals and its snack total — the meal-breakdown
  /// card's data. Empty (no meals, no snack bites) when the day has no bite.
  DayMealBreakdown get selectedBreakdown => _selectedBreakdown;

  bool _isBreakdownLoading = false;

  /// Whether a [selectDay] re-query is in flight — lets the card show its own
  /// spinner without blocking the rest of the screen.
  bool get isBreakdownLoading => _isBreakdownLoading;

  /// Selects [day] for the breakdown card: normalises to local midnight, marks
  /// the card loading, re-queries [BiteAnalytics.breakdownForDay], and notifies.
  /// The rest of the screen's metrics stay put — only the breakdown follows.
  Future<void> selectDay(DateTime day) async {
    _selectedDay = DateTime(day.year, day.month, day.day);
    _isBreakdownLoading = true;
    notifyListeners();
    _selectedBreakdown = await _analytics.breakdownForDay(_selectedDay);
    _isBreakdownLoading = false;
    notifyListeners();
  }

  /// The number of meals logged today — clusters that reached
  /// [BiteAnalytics.minMealBites]. 0 when today has no qualifying meal. Stays a
  /// today metric independent of [selectedDay].
  int get mealsToday => _mealsToday;

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
    _dailyWeights = _weightRepository.getWeightsInRange(from30, to);
    _averageLast30 = await _analytics.averagePerDay(from30, to);
    _maxLast30 = await _analytics.maxDay(from30, to);
    _averageLastYear = await _analytics.averagePerDay(fromYear, to);
    _selectedDay = today;
    _selectedBreakdown = await _analytics.breakdownForDay(today);
    _mealsToday = _selectedBreakdown.meals.length;
    _averageMealsLast30 = await _analytics.averageMealsPerDay(from30, to);
    _averageMealSizeLast30 = await _analytics.averageMealSize(from30, to);
    _isLoading = false;
    notifyListeners();
  }
}
