import 'package:food_locker/features/bite/data/bite_database.dart';

/// A gap longer than this between two consecutive bites closes the current
/// meal cluster and starts a new one. Measured bite-to-bite, not from the
/// cluster's start, so a long slow meal stays one cluster.
///
/// The single clustering rule shared by the analytics meal projections and the
/// Bite page's live current-meal count, so the two can't drift apart.
const Duration mealGapThreshold = Duration(minutes: 5);

/// Splits chronologically-ordered [bites] into clusters, breaking wherever a
/// gap from the previous bite exceeds [mealGapThreshold].
List<List<Bite>> clusterBites(List<Bite> bites) {
  final clusters = <List<Bite>>[];
  for (final bite in bites) {
    final current = clusters.isEmpty ? null : clusters.last;
    if (current != null &&
        bite.atMs - current.last.atMs <= mealGapThreshold.inMilliseconds) {
      current.add(bite);
    } else {
      clusters.add([bite]);
    }
  }
  return clusters;
}
