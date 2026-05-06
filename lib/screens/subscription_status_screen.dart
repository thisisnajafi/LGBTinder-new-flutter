import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/typography.dart';
import '../features/payments/providers/payment_providers.dart';
import '../routes/app_router.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/error_handling/empty_state.dart';
import '../widgets/loading/skeleton_loading.dart';
import '../widgets/navbar/app_bar_custom.dart';

class SubscriptionStatusScreen extends ConsumerWidget {
  const SubscriptionStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    final statusAsync = ref.watch(subscriptionStatusProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Subscription',
        showBackButton: true,
      ),
      body: statusAsync.when(
        loading: () => SkeletonLoading(),
        error: (_, __) => EmptyState(
          title: 'Unable to load subscription',
          message: 'Please try again.',
          icon: Icons.error_outline,
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(subscriptionStatusProvider),
          secondaryActionLabel: 'Contact support',
          onSecondaryAction: () => context.push(AppRoutes.helpSupport),
        ),
        data: (status) {
          final isActive = status?.isActive == true;
          final planName = status?.planName ?? (isActive ? 'Premium' : 'Free');
          final end = status?.endDate;

          return ListView(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.onlineGreen.withOpacity(0.15)
                                : AppColors.accentPurple.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                          ),
                          child: Icon(
                            isActive ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                            color: isActive ? AppColors.onlineGreen : AppColors.accentPurple,
                          ),
                        ),
                        SizedBox(width: AppSpacing.spacingMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isActive ? 'Active' : 'Not active',
                                style: AppTypography.caption.copyWith(
                                  color: isActive ? AppColors.onlineGreen : secondaryTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: AppSpacing.spacingXS),
                              Text(
                                planName,
                                style: AppTypography.h2.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (end != null) ...[
                      SizedBox(height: AppSpacing.spacingMD),
                      Text(
                        'Ends: ${end.toLocal().toString().split(".").first}',
                        style: AppTypography.body.copyWith(color: secondaryTextColor),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.spacingXL),
              if (isActive) ...[
                GradientButton(
                  text: 'Manage subscription',
                  onPressed: () => context.push(AppRoutes.subscriptionManagement),
                  isFullWidth: true,
                ),
              ] else ...[
                GradientButton(
                  text: 'Upgrade',
                  onPressed: () => context.push(AppRoutes.subscriptionPlans),
                  isFullWidth: true,
                ),
                SizedBox(height: AppSpacing.spacingMD),
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

