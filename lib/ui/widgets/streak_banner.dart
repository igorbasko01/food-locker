import 'package:flutter/material.dart';
import 'package:food_locker/features/days/data/day_manager.dart';

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

    if (stats.totalPastDays == 0) {
      return _buildCard(
        context,
        icon: Icons.auto_awesome_rounded,
        color: theme.colorScheme.primary,
        title: 'Welcome!',
        subtitle: 'Eat mindfully today. This is your first day of tracking!',
      );
    }
    
    if (stats.overateYesterday) {
      return _buildCard(
        context,
        icon: Icons.refresh_rounded,
        color: theme.colorScheme.tertiary,
        title: 'Fresh Start!',
        subtitle: 'You overate yesterday. Today is a brand new day to win!',
      );
    }
    
    if (stats.overeatingLast7 >= 3) {
      return _buildCard(
        context,
        icon: Icons.warning_amber_rounded,
        color: theme.colorScheme.error,
        title: 'Heads Up!',
        subtitle: 'You overate ${stats.overeatingLast7} times in the last 7 days. Stay strong today!',
      );
    }

    if (stats.streakDays >= 2) {
      return _buildCard(
        context,
        icon: Icons.local_fire_department_rounded,
        color: Colors.orange,
        title: '${stats.streakDays}-Day Streak!',
        subtitle: 'You are doing great! Keep the momentum going.',
      );
    }

    // Default or minimal streak case
    if (stats.streakDays == 1) {
       return _buildCard(
        context,
        icon: Icons.check_circle_outline_rounded,
        color: theme.colorScheme.primary,
        title: 'Good Job!',
        subtitle: 'You finished yesterday strong. Let\'s keep it going today!',
      );
    }

    return null;
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
