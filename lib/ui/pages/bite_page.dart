import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_locker/features/bite/data/bite_manager.dart';
import 'package:food_locker/features/bite/data/pacing_zone.dart';
import 'package:food_locker/ui/widgets/pacing_zone_style.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// The main bite-logging screen.
///
/// One big tap = one bite, recorded immediately and never blocked; the day's
/// running count — the headline metric — sits above the button and re-queries
/// after every tap. The button itself is the pacing surface, colouring the
/// current zone derived from the time since the last bite.
///
/// Logging a meal is a stop-start affair — you eat a bite, tap, wait, eat
/// again — and those gaps can be longer than the system screen timeout, which
/// would blank the screen mid-meal. So each tap keeps the screen awake across
/// the whole pacing interval — until the `b2` boundary (when the next bite is
/// recommended) plus a [_clearGrace] cushion — resetting that window on every
/// bite. Once it lapses with no new bite the wake-lock is released and the
/// OS's normal sleep behaviour resumes. The lock is also released whenever the
/// tab is hidden, the app is backgrounded, or this page is disposed, so it
/// never leaks beyond this screen.
class BitePage extends StatefulWidget {
  const BitePage({super.key, this.isActive = true});

  /// Whether this page is the visible tab. When `false` the wake-lock is
  /// released so it does not hold the screen on from behind another tab.
  final bool isActive;

  @override
  State<BitePage> createState() => _BitePageState();
}

class _BitePageState extends State<BitePage> with WidgetsBindingObserver {
  /// Extra time the screen is held awake past the `b2` boundary, so it does not
  /// blank the instant the next bite becomes due.
  static const Duration _clearGrace = Duration(seconds: 15);

  Timer? _releaseTimer;
  bool _wakeEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(BitePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive) {
      // Left the Bite tab: drop the lock immediately rather than waiting out
      // the remainder of the window on some other screen.
      _releaseWakelock();
    } else if (!oldWidget.isActive) {
      // Became the visible tab: re-read the store so the day count, the
      // current-meal number, and the pacing state reflect any day rollover or
      // meal that ended while another tab was showing.
      _refreshBiteState();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      // Nothing to keep awake once the app is no longer in the foreground.
      _releaseWakelock();
    } else if (widget.isActive) {
      // Resumed onto the Bite tab: the app may have sat backgrounded across a
      // day boundary or the end of a meal, so re-read the store.
      _refreshBiteState();
    }
  }

  void _refreshBiteState() {
    unawaited(context.read<BiteManager>().refresh());
  }

  Future<void> _handleBite() async {
    final biteManager = context.read<BiteManager>();
    await biteManager.logBite();
    // Hold the screen on for the whole pacing interval (b2) plus a grace
    // cushion, measured from this bite; the next bite re-arms it.
    _keepAwakeForWindow(biteManager.b2 + _clearGrace);
  }

  void _keepAwakeForWindow(Duration window) {
    if (!widget.isActive) return;
    _releaseTimer?.cancel();
    _releaseTimer = Timer(window, _releaseWakelock);
    if (!_wakeEnabled) {
      _wakeEnabled = true;
      WakelockPlus.enable();
    }
  }

  void _releaseWakelock() {
    _releaseTimer?.cancel();
    _releaseTimer = null;
    if (_wakeEnabled) {
      _wakeEnabled = false;
      WakelockPlus.disable();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _releaseWakelock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final biteManager = context.watch<BiteManager>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Force full width: inside the app shell's IndexedStack (loose sizing)
          // this bare Column would otherwise shrink to the button's width and pin
          // left, off-centre from the app-bar title.
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  "Today's Bites",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${biteManager.todayCount}',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                // The in-progress sitting's running count, shown only while a
                // meal is actually underway (0 once the sitting has ended).
                if (biteManager.currentMealBites > 0) ...[
                  const SizedBox(height: 4),
                  Semantics(
                    label:
                        'Current meal: ${biteManager.currentMealBites} bites',
                    excludeSemantics: true,
                    child: Text(
                      'This meal: ${biteManager.currentMealBites}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                _BiteButton(
                  zone: biteManager.pacingZone,
                  remaining: biteManager.isPacing
                      ? biteManager.b2 -
                          (biteManager.sinceLastBite ?? Duration.zero)
                      : null,
                  onTap: _handleBite,
                ),
                const Spacer(),
                Text(
                  'Tap for each bite',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The large circular tap target and the pacing surface itself: its fill
/// animates to the current [zone]'s colour (red / amber / green) and, below its
/// "Bite" action label, it names the current zone — so the feedback lives under
/// the thumb. [remaining] — the seconds left until the clear point — shows
/// inside the button while pacing, hidden at `b2`.
///
/// Logging stays feedback, not lockout: the button is tappable in every zone, a
/// tap always logs immediately, and the colour never green-lights an early bite
/// (red/amber mean "still costly"). The fixed 'Log a bite' semantics label keeps
/// the action announced independently of the visual zone label.
class _BiteButton extends StatelessWidget {
  const _BiteButton({
    required this.zone,
    required this.remaining,
    required this.onTap,
  });

  final PacingZone zone;
  final Duration? remaining;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = PacingZoneStyle.of(zone);
    final countdown = remaining;

    return Semantics(
      button: true,
      label: 'Log a bite',
      child: AnimatedContainer(
        // Animate zone-colour changes so they glide instead of snapping.
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: style.fillColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Centred so the icon and labels don't shift as the countdown
                // appears and disappears.
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restaurant_rounded,
                      size: 60,
                      color: style.onFillColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bite',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: style.onFillColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      style.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: style.onFillColor.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (countdown != null)
                  Positioned(
                    bottom: 24,
                    child: Text(
                      '${_ceilSeconds(countdown)}s',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: style.onFillColor.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Seconds left, rounded *up* and floored at zero, so the countdown reads a
  /// whole "1s" for the last fractional second rather than flashing "0s" while
  /// still pacing.
  static int _ceilSeconds(Duration d) {
    final ms = d.inMilliseconds;
    if (ms <= 0) return 0;
    return (ms / Duration.millisecondsPerSecond).ceil();
  }
}
