import 'package:flutter/material.dart';
import 'package:food_locker/features/weight/data/weight_manager.dart';

class StreakBanner extends StatelessWidget {
  final OvereatingStats stats;

  const StreakBanner({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    // Determine content based on stats
    final Widget? banner = _buildBanner(context);
    
    if (banner == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: banner,
    );
  }

  Widget? _buildBanner(BuildContext context) {
    final theme = Theme.of(context);
    final type = stats.currentStreakType;
    final length = stats.currentStreakLength;

    if (type == null || length == 0) {
      return _buildCard(
        context,
        icon: Icons.history_rounded,
        color: theme.colorScheme.primary,
        title: 'Start a new streak!',
        subtitle: 'Log your weight daily to build your momentum.',
      );
    }
    
    if (type == StreakType.overeating) {
      if (length >= 2) {
        return _buildCard(
          context,
          icon: Icons.warning_rounded,
          color: theme.colorScheme.error,
          title: '$length-Day Overeating Streak',
          subtitle: 'You\'ve been overeating lately. Break the cycle today!',
        );
      } else {
        return _buildCard(
          context,
          icon: Icons.refresh_rounded,
          color: theme.colorScheme.tertiary,
          title: 'Fresh Start!',
          subtitle: 'You overate last time. Today is a brand new day to win!',
        );
      }
    } else {
      if (length >= 2) {
        return _buildCard(
          context,
          icon: Icons.local_fire_department_rounded,
          color: Colors.orange,
          title: '$length-Day Streak!',
          subtitle: 'You are doing great! Keep the momentum going.',
        );
      } else {
        return _buildCard(
          context,
          icon: Icons.check_circle_outline_rounded,
          color: theme.colorScheme.primary,
          title: 'Good Job!',
          subtitle: 'You finished last time strong. Let\'s keep it going today!',
        );
      }
    }
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
