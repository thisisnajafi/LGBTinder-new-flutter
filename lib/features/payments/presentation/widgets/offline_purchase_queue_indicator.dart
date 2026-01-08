import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../providers/google_play_billing_provider.dart';

/// Widget to display offline purchase queue indicator
/// Shows when purchases are queued for processing when connection is restored
class OfflinePurchaseQueueIndicator extends ConsumerWidget {
  final VoidCallback? onRetry;

  const OfflinePurchaseQueueIndicator({
    Key? key,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to purchase updates to detect pending purchases
    final purchaseUpdates = ref.watch(purchaseUpdatesProvider);

    // Check for pending purchases
    final pendingPurchases = purchaseUpdates.when(
      data: (purchases) => purchases.where((p) => p.status == PurchaseStatus.pending).toList(),
      loading: () => <PurchaseDetails>[],
      error: (_, __) => <PurchaseDetails>[],
    );

    if (pendingPurchases.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      margin: EdgeInsets.all(AppSpacing.spacingMD),
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.accentYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(
          color: AppColors.accentYellow.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.cloud_off,
                color: AppColors.accentYellow,
                size: 20,
              ),
              SizedBox(width: AppSpacing.spacingSM),
              Expanded(
                child: Text(
                  'Pending Purchases',
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingSM,
                  vertical: AppSpacing.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
                child: Text(
                  '${pendingPurchases.length}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.spacingSM),

          // Message
          Text(
            pendingPurchases.length == 1
                ? 'You have 1 purchase waiting to be processed. It will be completed when your connection is restored.'
                : 'You have ${pendingPurchases.length} purchases waiting to be processed. They will be completed when your connection is restored.',
            style: AppTypography.caption.copyWith(
              color: secondaryTextColor,
            ),
          ),

          if (onRetry != null) ...[
            SizedBox(height: AppSpacing.spacingMD),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, size: 16),
              label: const Text('Retry Now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentYellow,
                side: BorderSide(color: AppColors.accentYellow),
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Provider for pending purchases count
final pendingPurchasesCountProvider = Provider<int>((ref) {
  final purchaseUpdates = ref.watch(purchaseUpdatesProvider);
  return purchaseUpdates.when(
    data: (purchases) => purchases.where((p) => p.status == PurchaseStatus.pending).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
