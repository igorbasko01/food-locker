import 'package:flutter/foundation.dart';
import 'package:food_locker/features/bite/data/bite_repository.dart';

/// UI-facing state holder for the bite-logging screen (Phase 4).
///
/// Owns the running bite count for the current local day in memory and, after
/// every tap, writes through the [BiteRepository] then re-reads the count so the
/// surfaced number stays consistent with the store — mirroring the weight
/// feature's write-through-then-refresh pattern.
///
/// Bite count is the headline metric (§0): [logBite] never blocks (§3a) and the
/// count re-queries after each tap (§4, Phase 4).
class BiteManager extends ChangeNotifier {
  BiteManager(this._repository);

  final BiteRepository _repository;

  int _todayCount = 0;

  /// Bites logged so far during the current local day — the headline metric
  /// (§3c). Zero until [initialize] (or a [logBite]) has run.
  int get todayCount => _todayCount;

  /// Loads today's count from the store so the screen opens with the right
  /// number even after an app restart.
  Future<void> initialize() async {
    await _refreshTodayCount();
  }

  /// Records one bite at the current instant — one tap = one bite, persisted
  /// immediately and never blocked (§3a) — then refreshes today's count.
  Future<void> logBite() async {
    await _repository.logBite(DateTime.now());
    await _refreshTodayCount();
  }

  Future<void> _refreshTodayCount() async {
    final now = DateTime.now();
    // Local-day bounds as a half-open window `[startOfDay, startOfNextDay)`.
    // Building the next day via the DateTime constructor (day + 1) normalizes
    // month/year rollovers and lands on local midnight — DST-correct, unlike
    // adding a fixed 24-hour Duration.
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfNextDay = DateTime(now.year, now.month, now.day + 1);
    _todayCount = await _repository.biteCount(startOfDay, startOfNextDay);
    notifyListeners();
  }
}
