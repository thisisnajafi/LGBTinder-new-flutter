import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/spacing_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../features/auth/providers/auth_provider.dart';
import '../routes/app_router.dart';
import '../widgets/buttons/gradient_button.dart';

/// Shown when the backend reports the account is banned.
class BannedAccountScreen extends ConsumerWidget {
  const BannedAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return PremiumDetailScaffold(
      title: 'Account suspended',
      subtitle: 'Access restricted',
      onBack: () => context.go(AppRoutes.welcome),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.spacingXXL),
            PremiumShell(
              child: Column(
                children: [
                  AppSvgIcon(
                    assetPath: AppIcons.shieldSlash,
                    size: 72,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.spacingLG),
                  Text(
                    'Your account has been banned',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacingMD),
                  Text(
                    'You can no longer use LGBTinder. All matches have been removed. '
                    'Contact support if you believe this is a mistake.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.spacingLG,
          AppSpacing.spacingSM,
          AppSpacing.spacingLG,
          AppSpacing.spacingLG,
        ),
        child: GradientButton(
          text: 'Back to welcome',
          iconPath: AppIcons.logout,
          isFullWidth: true,
          onPressed: () async {
            await ref.read(authProvider.notifier).logout(silent: true);
            if (context.mounted) {
              context.go(AppRoutes.welcome);
            }
          },
        ),
      ),
    );
  }
}
