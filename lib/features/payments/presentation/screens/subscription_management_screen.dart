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
import '../widgets/subscription_renewal_reminder.dart';
import '../widgets/offline_purchase_queue_indicator.dart';
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

  List<Map<String, dynamic>>? _googlePlaySubscriptions;
  bool _isLoadingGooglePlay = false;

  Future<void> _loadSubscriptionStatus() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final status = await paymentService.getSubscriptionStatus();

      // Also load Google Play subscriptions
      _loadGooglePlaySubscriptions();

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

  Future<void> _loadGooglePlaySubscriptions() async {
    setState(() {
      _isLoadingGooglePlay = true;
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final subscriptions = await paymentService.getGooglePlayActiveSubscriptions();

      if (mounted) {
        setState(() {
          _googlePlaySubscriptions = subscriptions;
          _isLoadingGooglePlay = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGooglePlay = false;
        });
      }
    }
  }

  Future<void> _cancelSubscription({int? googlePlaySubscriptionId}) async {
    // Check if it's a Google Play subscription
    if (googlePlaySubscriptionId != null) {
      await _cancelGooglePlaySubscription(googlePlaySubscriptionId);
      return;
    }

    // Otherwise, it's a Stripe subscription
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

  Future<void> _cancelGooglePlaySubscription(int subscriptionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your Google Play subscription? '
          'You will lose access to premium features at the end of your billing period. '
          'You can manage your subscription in Google Play Store.',
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
      await paymentService.cancelGooglePlaySubscription(subscriptionId);

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

                      // Subscription Renewal Reminder
                      if (_subscriptionStatus?.isActive == true && _subscriptionStatus?.endDate != null)
                        SubscriptionRenewalReminder(
                          subscriptionStatus: _subscriptionStatus!,
                          onManageSubscription: () {
                            // Already on management screen
                          },
                          onCancelAutoRenewal: () {
                            if (_subscriptionStatus?.stripeSubscriptionId != null) {
                              _cancelSubscription();
                            } else if (_googlePlaySubscriptions != null && _googlePlaySubscriptions!.isNotEmpty) {
                              final sub = _googlePlaySubscriptions!.first;
                              final subscriptionId = sub['id'] is int
                                  ? sub['id'] as int
                                  : int.tryParse(sub['id'].toString());
                              if (subscriptionId != null) {
                                _cancelSubscription(googlePlaySubscriptionId: subscriptionId);
                              }
                            }
                          },
                          onChangePlan: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SubscriptionPlansScreen(),
                              ),
                            );
                          },
                        ),

                      // Offline Purchase Queue Indicator
                      OfflinePurchaseQueueIndicator(
                        onRetry: () {
                          // Retry processing pending purchases
                          _loadSubscriptionStatus();
                        },
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

                      // Google Play Subscriptions
                      if (_googlePlaySubscriptions != null && _googlePlaySubscriptions!.isNotEmpty) ...[
                        Text(
                          'Google Play Subscriptions',
                          style: AppTypography.h3.copyWith(color: textColor),
                        ),
                        SizedBox(height: AppSpacing.spacingMD),
                        ..._googlePlaySubscriptions!.map((sub) => _buildGooglePlaySubscriptionCard(
                          sub,
                          textColor,
                          secondaryTextColor,
                          surfaceColor,
                          borderColor,
                        )),
                        SizedBox(height: AppSpacing.spacingLG),
                      ],

                      // Actions
                      if (_subscriptionStatus?.isActive == true || (_googlePlaySubscriptions != null && _googlePlaySubscriptions!.isNotEmpty)) ...[
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
                        if (_subscriptionStatus?.stripeSubscriptionId != null)
                          OutlinedButton(
                            onPressed: _isCancelling ? null : () => _cancelSubscription(),
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
                                : const Text('Cancel Stripe Subscription'),
                          ),
                        // Restore Purchases Button
                        SizedBox(height: AppSpacing.spacingMD),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _restorePurchases,
                          icon: Icon(Icons.restore),
                          label: Text('Restore Purchases'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accentPurple,
                            side: BorderSide(color: AppColors.accentPurple),
                            minimumSize: const Size(double.infinity, 50),
                          ),
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
                        SizedBox(height: AppSpacing.spacingMD),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _restorePurchases,
                          icon: Icon(Icons.restore),
                          label: Text('Restore Purchases'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accentPurple,
                            side: BorderSide(color: AppColors.accentPurple),
                            minimumSize: const Size(double.infinity, 50),
                          ),
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

  Widget _buildGooglePlaySubscriptionCard(
    Map<String, dynamic> subscription,
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    final planName = subscription['plan']?['title']?.toString() ?? 'Unknown Plan';
    final status = subscription['status']?.toString() ?? 'unknown';
    final billingCycle = subscription['billing_cycle']?.toString() ?? 'monthly';
    final startDate = subscription['start_date'] != null
        ? DateTime.tryParse(subscription['start_date'].toString())
        : null;
    final endDate = subscription['end_date'] != null
        ? DateTime.tryParse(subscription['end_date'].toString())
        : null;
    final subscriptionId = subscription['id'] is int
        ? subscription['id'] as int
        : int.tryParse(subscription['id'].toString());

    int? daysRemaining;
    if (endDate != null) {
      final now = DateTime.now();
      if (endDate.isAfter(now)) {
        daysRemaining = endDate.difference(now).inDays;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
      padding: EdgeInsets.all(AppSpacing.spacingMD),
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
              Icon(
                Icons.android,
                color: AppColors.onlineGreen,
                size: 24,
              ),
              SizedBox(width: AppSpacing.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName,
                      style: AppTypography.h3.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Google Play Subscription',
                      style: AppTypography.caption.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingSM,
                  vertical: AppSpacing.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: status == 'active'
                      ? AppColors.onlineGreen.withOpacity(0.2)
                      : AppColors.accentRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: status == 'active'
                        ? AppColors.onlineGreen
                        : AppColors.accentRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildDetailRow('Billing Cycle', billingCycle.toUpperCase(), textColor, secondaryTextColor),
          if (startDate != null)
            _buildDetailRow('Start Date', _formatDate(startDate), textColor, secondaryTextColor),
          if (endDate != null)
            _buildDetailRow('End Date', _formatDate(endDate), textColor, secondaryTextColor),
          if (daysRemaining != null)
            _buildDetailRow(
              'Days Remaining',
              daysRemaining > 0 ? '$daysRemaining days' : 'Expired',
              textColor,
              secondaryTextColor,
            ),
          if (subscriptionId != null && status == 'active') ...[
            SizedBox(height: AppSpacing.spacingMD),
            OutlinedButton(
              onPressed: _isCancelling
                  ? null
                  : () => _cancelSubscription(googlePlaySubscriptionId: subscriptionId),
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
          ],
        ],
      ),
    );
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final restored = await paymentService.restorePurchases();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              restored
                  ? 'Purchases restored successfully'
                  : 'No purchases found to restore',
            ),
            backgroundColor: restored ? AppColors.onlineGreen : Colors.orange,
          ),
        );
        // Reload status
        _loadSubscriptionStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore purchases: ${e.toString()}'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
