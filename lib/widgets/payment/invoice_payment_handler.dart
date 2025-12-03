// Widget: InvoicePaymentHandler
// Invoice payment handler
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../buttons/gradient_button.dart';
import '../modals/alert_dialog_custom.dart';

/// Invoice payment handler widget
/// Displays invoice details and handles payment
class InvoicePaymentHandler extends ConsumerWidget {
  final String invoiceId;
  final String amount;
  final String? description;
  final DateTime? dueDate;
  final String? status; // "pending", "paid", "failed"
  final Function()? onPay;
  final Function()? onViewDetails;

  const InvoicePaymentHandler({
    Key? key,
    required this.invoiceId,
    required this.amount,
    this.description,
    this.dueDate,
    this.status,
    this.onPay,
    this.onViewDetails,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (status?.toLowerCase()) {
      case 'paid':
        return AppColors.onlineGreen;
      case 'failed':
        return AppColors.notificationRed;
      case 'pending':
      default:
        return AppColors.warningYellow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invoice #$invoiceId',
                style: AppTypography.h3.copyWith(color: textColor),
              ),
              if (status != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                    vertical: AppSpacing.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  ),
                  child: Text(
                    status!.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            amount,
            style: AppTypography.h1.copyWith(
              color: AppColors.accentPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (description != null) ...[
            SizedBox(height: AppSpacing.spacingSM),
            Text(
              description!,
              style: AppTypography.body.copyWith(color: secondaryTextColor),
            ),
          ],
          if (dueDate != null) ...[
            SizedBox(height: AppSpacing.spacingSM),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: secondaryTextColor,
                ),
                SizedBox(width: AppSpacing.spacingXS),
                Text(
                  'Due: ${_formatDate(dueDate!)}',
                  style: AppTypography.caption.copyWith(color: secondaryTextColor),
                ),
              ],
            ),
          ],
          SizedBox(height: AppSpacing.spacingLG),
          Row(
            children: [
              if (onViewDetails != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                    ),
                    child: Text(
                      'View Details',
                      style: AppTypography.button.copyWith(
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              if (onViewDetails != null && onPay != null)
                SizedBox(width: AppSpacing.spacingMD),
              if (onPay != null && status?.toLowerCase() != 'paid')
                Expanded(
                  child: GradientButton(
                    text: 'Pay Now',
                    onPressed: onPay,
                    isFullWidth: true,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
