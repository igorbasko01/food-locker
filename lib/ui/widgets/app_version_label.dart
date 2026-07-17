import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A muted footer showing the installed app version, read at runtime so it
/// tracks `pubspec.yaml` without a hardcoded string. Renders nothing until the
/// version resolves (and on error), so the layout never flashes a placeholder.
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Center(
            child: Text(
              'Version ${snapshot.data!.version}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}
