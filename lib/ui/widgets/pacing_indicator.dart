import 'package:flutter/material.dart';
import 'package:food_locker/features/bite/data/pacing_zone.dart';

/// The pacing feedback banner (§3b, Phase 5).
///
/// A feedback metronome, not a gate: it renders the current [PacingZone] as a
/// colour and a message that say *how costly it is to bite right now*, easing to
/// green once you're in the clear. It never green-lights an early bite and never
/// blocks logging — the tap button below stays live in every zone.
///
/// The colours and messages are fixed app constants (not theme-derived) so the
/// red / amber / green semantics read the same regardless of the app's teal
/// palette or platform.
class PacingIndicator extends StatelessWidget {
  const PacingIndicator({super.key, required this.zone});

  final PacingZone zone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _PacingZoneStyle.of(zone);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: style.color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, color: style.color, size: 22),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              style.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: style.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The colour, icon, and message for each pacing zone — the app constants the
/// visualization is built from (§3b). Messages are about *chewing* while you
/// wait; reaching the clear zone is the only readiness cue.
class _PacingZoneStyle {
  const _PacingZoneStyle({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  static _PacingZoneStyle of(PacingZone zone) {
    switch (zone) {
      case PacingZone.tooSoon:
        return const _PacingZoneStyle(
          color: Color(0xFFD32F2F), // red
          icon: Icons.hourglass_top_rounded,
          message: 'Too soon — keep chewing',
        );
      case PacingZone.holdOn:
        return const _PacingZoneStyle(
          color: Color(0xFFF9A825), // amber
          icon: Icons.hourglass_bottom_rounded,
          message: 'Almost — hold on a moment',
        );
      case PacingZone.inTheClear:
        return const _PacingZoneStyle(
          color: Color(0xFF2E7D32), // green
          icon: Icons.check_circle_rounded,
          message: "You're in the clear",
        );
    }
  }
}
