import 'package:flutter/material.dart';
import 'package:food_locker/features/bite/data/bite_manager.dart';
import 'package:food_locker/ui/widgets/pacing_indicator.dart';
import 'package:provider/provider.dart';

/// The main bite-logging screen (Phases 4–5).
///
/// One big tap = one bite, recorded immediately and never blocked (§3a); the
/// day's running count — the headline metric — sits above the button and
/// re-queries after every tap. The pacing feedback banner (§3b) sits between
/// the count and the button, colouring the current zone derived from the time
/// since the last bite.
class BitePage extends StatelessWidget {
  const BitePage({super.key});

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
              _BiteButton(onTap: biteManager.logBite),
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
