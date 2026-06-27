import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../features/payments/providers/payment_providers.dart';
import '../routes/app_router.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/error_handling/empty_state.dart';
import '../widgets/loading/skeleton_loading.dart';

class SubscriptionStatusScreen extends ConsumerWidget {
  const SubscriptionStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final statusAsync = ref.watch(subscriptionStatusProvider);

    return PremiumDetailScaffold(
      title: 'Subscription',
      subtitle: 'Your membership status',
      body: statusAsync.when(
        loading: () => const SkeletonLoading(),
        error: (_, __) => EmptyState(
          title: 'Unable to load subscription',
          message: 'Please try again.',
          iconPath: AppIcons.warning,
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(subscriptionStatusProvider),
          secondaryActionLabel: 'Contact support',
          onSecondaryAction: () => context.push(AppRoutes.helpSupport),
        ),
        data: (status) {
          final isActive = status?.isActive == true;
          final planName = status?.planName ?? (isActive ? 'Premium' : 'Free');
          final end = status?.endDate;
          final statusColor =
              isActive ? AppColors.feedbackSuccess : AppColors.accentViolet;
          final statusIcon =
              isActive ? AppIcons.shieldTick : AppIcons.crown;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.spacingLG),
            children: [
              PremiumShell(
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: AppSvgIcon(
                          assetPath: statusIcon,
                          size: 24,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isActive ? 'Active' : 'Not active',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spacingXS),
                          Text(
                            planName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (end != null) ...[
                            const SizedBox(height: AppSpacing.spacingSM),
                            Text(
                              'Ends: ${end.toLocal().toString().split('.').first}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.spacingXL),
              if (isActive) ...[
                GradientButton(
                  text: 'Manage subscription',
                  onPressed: () =>
                      context.push(AppRoutes.subscriptionManagement),
                  isFullWidth: true,
                ),
              ] else ...[
                GradientButton(
                  text: 'Upgrade',
                  onPressed: () => context.push(AppRoutes.subscriptionPlans),
                  isFullWidth: true,
                ),
                const SizedBox(height: AppSpacing.spacingMD),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push(AppRoutes.tierComparison),
                    child: const Text('Compare tiers'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
