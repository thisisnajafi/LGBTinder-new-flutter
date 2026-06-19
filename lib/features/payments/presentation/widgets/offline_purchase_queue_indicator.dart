import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../providers/google_play_billing_provider.dart';

/// Pending Google Play purchases shown in a settings-style grouped section.
class OfflinePurchaseQueueIndicator extends ConsumerWidget {
  final VoidCallback? onRetry;

  const OfflinePurchaseQueueIndicator({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseUpdates = ref.watch(purchaseUpdatesProvider);

    final pendingPurchases = purchaseUpdates.when(
      data: (purchases) =>
          purchases.where((p) => p.status == PurchaseStatus.pending).toList(),
      loading: () => <PurchaseDetails>[],
      error: (_, __) => <PurchaseDetails>[],
    );

    if (pendingPurchases.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final count = pendingPurchases.length;
    final message = count == 1
        ? 'You have 1 purchase waiting to be processed. It will complete when your connection is restored.'
        : 'You have $count purchases waiting to be processed. They will complete when your connection is restored.';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.spacingXL),
      child: PremiumSettingsGroup(
        title: 'Pending purchases',
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSvgIcon(
                  assetPath: AppIcons.cloud,
                  size: 20,
                  color: AppColors.feedbackWarning,
                ),
                const SizedBox(width: AppSpacing.spacingSM),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingSM,
                    vertical: AppSpacing.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.feedbackWarning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.feedbackWarning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            PremiumSettingsTile(
              iconPath: AppIcons.refreshCircle,
              title: 'Retry now',
              subtitle: 'Process pending purchases',
              onTap: onRetry!,
            ),
        ],
      ),
    );
  }
}

/// Provider for pending purchases count
final pendingPurchasesCountProvider = Provider<int>((ref) {
  final purchaseUpdates = ref.watch(purchaseUpdatesProvider);
  return purchaseUpdates.when(
    data: (purchases) =>
        purchases.where((p) => p.status == PurchaseStatus.pending).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
