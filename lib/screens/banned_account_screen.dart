import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/spacing_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_svg_icon.dart';
import '../features/auth/providers/auth_provider.dart';
import '../routes/app_router.dart';

/// Shown when the backend reports the account is banned.
class BannedAccountScreen extends ConsumerWidget {
  const BannedAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: AppSvgIcon(
                  assetPath: AppIcons.shieldSlash,
                  size: 72,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.spacingLG),
              Text(
                'Account suspended',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.spacingMD),
              Text(
                'Your account has been banned and you can no longer use LGBTinder. '
                'All matches have been removed. Contact support if you believe this is a mistake.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout(silent: true);
                  if (context.mounted) {
                    context.go(AppRoutes.welcome);
                  }
                },
                child: const Text('Back to welcome'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
