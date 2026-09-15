import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Badge colors/labels for Google Play purchase status (PERF-FEAT-PAY-003).
class PurchaseStatusStyle {
  const PurchaseStatusStyle({
    required this.badgeColor,
    required this.foregroundColor,
    required this.label,
  });

  final Color badgeColor;
  final Color foregroundColor;
  final String label;

  factory PurchaseStatusStyle.fromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const PurchaseStatusStyle(
          badgeColor: AppColors.onlineGreen,
          foregroundColor: AppColors.backgroundLight,
          label: 'Completed',
        );
      case 'pending':
        return const PurchaseStatusStyle(
          badgeColor: AppColors.feedbackWarning,
          foregroundColor: AppColors.backgroundLight,
          label: 'Pending',
        );
      case 'cancelled':
        return const PurchaseStatusStyle(
          badgeColor: AppColors.textTertiaryLight,
          foregroundColor: AppColors.backgroundLight,
          label: 'Cancelled',
        );
      case 'refunded':
        return const PurchaseStatusStyle(
          badgeColor: AppColors.accentRed,
          foregroundColor: AppColors.backgroundLight,
          label: 'Refunded',
        );
      default:
        return PurchaseStatusStyle(
          badgeColor: AppColors.textTertiaryLight,
          foregroundColor: AppColors.backgroundLight,
          label: status,
        );
    }
  }
}
