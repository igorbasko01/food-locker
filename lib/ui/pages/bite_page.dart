import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_locker/features/bite/data/bite_manager.dart';
import 'package:food_locker/ui/widgets/pacing_indicator.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// The main bite-logging screen (Phases 4–5).
///
/// One big tap = one bite, recorded immediately and never blocked (§3a); the
/// day's running count — the headline metric — sits above the button and
/// re-queries after every tap. The pacing feedback banner (§3b) sits between
/// the count and the button, colouring the current zone derived from the time
/// since the last bite.
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
    // Left the Bite tab: drop the lock immediately rather than waiting out the
    // remainder of the window on some other screen.
    if (!widget.isActive) {
      _releaseWakelock();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Nothing to keep awake once the app is no longer in the foreground.
    if (state != AppLifecycleState.resumed) {
      _releaseWakelock();
    }
  }

  Future<void> _handleBite() async {
    final biteManager = context.read<BiteManager>();
    await biteManager.logBite();
    // Hold the screen on for the whole pacing interval (b2) plus a grace
    // cushion, measured from this bite; the next bite re-arms it.
    _keepAwakeForWindow(biteManager.b2 + _clearGrace);
  }

  /// Enables the wake-lock (if not already held) and (re)arms the release
  /// timer so the screen stays on for [window] from now.
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
          child: Column(
            children: [
              const Spacer(),
              Text(
                "Today's Bites",
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
              const Spacer(),
              PacingIndicator(zone: biteManager.pacingZone),
              const SizedBox(height: 24),
              _BiteButton(onTap: _handleBite),
              const Spacer(),
              Text(
                'Tap for each bite',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// The large circular tap target — the primary action of the whole screen.
class _BiteButton extends StatelessWidget {
  const _BiteButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Log a bite',
      child: Material(
        color: theme.colorScheme.primary,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 220,
            height: 220,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_rounded,
                  size: 72,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Bite',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
