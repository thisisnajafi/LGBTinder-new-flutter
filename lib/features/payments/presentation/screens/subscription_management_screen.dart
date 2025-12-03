// Screen: SubscriptionManagementScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../widgets/navbar/app_bar_custom.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_loading.dart';
import '../../providers/payment_providers.dart';
import '../../data/models/subscription_plan.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../shared/services/error_handler_service.dart';
import 'subscription_plans_screen.dart';

/// Subscription management screen - View and manage current subscription
class SubscriptionManagementScreen extends ConsumerStatefulWidget {
  const SubscriptionManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends ConsumerState<SubscriptionManagementScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  SubscriptionStatus? _subscriptionStatus;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final status = await paymentService.getSubscriptionStatus();

      if (mounted) {
        setState(() {
          _subscriptionStatus = status;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelSubscription() async {
    if (_subscriptionStatus?.stripeSubscriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active subscription to cancel'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: Text(
          'Are you sure you want to cancel your ${_subscriptionStatus?.planName ?? 'subscription'}? '
          'You will lose access to premium features at the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      await paymentService.cancelSubscription(_subscriptionStatus!.stripeSubscriptionId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription cancelled successfully'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
        // Reload status
        _loadSubscriptionStatus();
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to cancel subscription',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to cancel subscription',
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Subscription',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            onPressed: _loadSubscriptionStatus,
          ),
        ],
      ),
      body: _isLoading
          ? SkeletonLoading()
          : _hasError && _subscriptionStatus == null
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage ?? 'Failed to load subscription status',
                  onRetry: _loadSubscriptionStatus,
                )
              : RefreshIndicator(
                  onRefresh: _loadSubscriptionStatus,
                  child: ListView(
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    children: [
                      // Subscription status card
                      Container(
                        padding: EdgeInsets.all(AppSpacing.spacingLG),
                        decoration: BoxDecoration(
                          color: _subscriptionStatus?.isActive == true
                              ? AppColors.accentPurple.withOpacity(0.1)
                              : surfaceColor,
                          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                          border: Border.all(
                            color: _subscriptionStatus?.isActive == true
                                ? AppColors.accentPurple
                                : borderColor,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _subscriptionStatus?.isActive == true
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _subscriptionStatus?.isActive == true
                                      ? AppColors.onlineGreen
                                      : AppColors.accentRed,
                                  size: 32,
                                ),
                                SizedBox(width: AppSpacing.spacingMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _subscriptionStatus?.isActive == true
                                            ? 'Active Subscription'
                                            : 'No Active Subscription',
                                        style: AppTypography.h2.copyWith(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_subscriptionStatus?.planName != null) ...[
                                        SizedBox(height: AppSpacing.spacingXS),
                                        Text(
                                          _subscriptionStatus!.planName!,
                                          style: AppTypography.body.copyWith(
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_subscriptionStatus?.status != null) ...[
                              SizedBox(height: AppSpacing.spacingMD),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.spacingSM,
                                  vertical: AppSpacing.spacingXS,
                                ),
                                decoration: BoxDecoration(
                                  color: _subscriptionStatus!.status == 'active'
                                      ? AppColors.onlineGreen.withOpacity(0.2)
                                      : surfaceColor,
                                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                                ),
                                child: Text(
                                  _subscriptionStatus!.status!.toUpperCase(),
                                  style: AppTypography.caption.copyWith(
                                    color: _subscriptionStatus!.status == 'active'
                                        ? AppColors.onlineGreen
                                        : secondaryTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: AppSpacing.spacingLG),

                      // Subscription details
                      if (_subscriptionStatus != null) ...[
                        Text(
                          'Subscription Details',
                          style: AppTypography.h3.copyWith(color: textColor),
                        ),
                        SizedBox(height: AppSpacing.spacingMD),
                        _buildDetailRow(
                          'Start Date',
                          _formatDate(_subscriptionStatus!.startDate),
                          textColor,
                          secondaryTextColor,
                        ),
                        _buildDetailRow(
                          'End Date',
                          _formatDate(_subscriptionStatus!.endDate),
                          textColor,
                          secondaryTextColor,
                        ),
                        if (_subscriptionStatus!.nextBillingDate != null)
                          _buildDetailRow(
                            'Next Billing',
                            _formatDate(_subscriptionStatus!.nextBillingDate),
                            textColor,
                            secondaryTextColor,
                          ),
                        _buildDetailRow(
                          'Auto Renew',
                          _subscriptionStatus!.autoRenew ? 'Yes' : 'No',
                          textColor,
                          secondaryTextColor,
                        ),
                        SizedBox(height: AppSpacing.spacingLG),
                      ],

                      // Actions
                      if (_subscriptionStatus?.isActive == true) ...[
                        GradientButton(
                          text: 'Upgrade Plan',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SubscriptionPlansScreen(),
                              ),
                            );
                          },
                          isFullWidth: true,
                        ),
                        SizedBox(height: AppSpacing.spacingMD),
                        OutlinedButton(
                          onPressed: _isCancelling ? null : _cancelSubscription,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accentRed,
                            side: BorderSide(color: AppColors.accentRed),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: _isCancelling
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Cancel Subscription'),
                        ),
                      ] else ...[
                        GradientButton(
                          text: 'Subscribe Now',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SubscriptionPlansScreen(),
                              ),
                            );
                          },
                          isFullWidth: true,
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingMD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: secondaryTextColor,
            ),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
