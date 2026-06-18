// Screen: SubscriptionManagementScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_grouped_list_card.dart';
import '../../../../core/widgets/app_settings_detail.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../providers/payment_providers.dart';
import '../../data/models/subscription_plan.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../shared/services/error_handler_service.dart';
import '../widgets/subscription_renewal_reminder.dart';
import '../widgets/offline_purchase_queue_indicator.dart';
import 'subscription_plans_screen.dart';

/// Subscription management screen — view and manage the current subscription.
class SubscriptionManagementScreen extends ConsumerStatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  ConsumerState<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends ConsumerState<SubscriptionManagementScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  SubscriptionStatus? _subscriptionStatus;
  bool _isCancelling = false;
  List<Map<String, dynamic>>? _googlePlaySubscriptions;

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
    try {
      final paymentService = ref.read(paymentServiceProvider);
      final subscriptions =
          await paymentService.getGooglePlayActiveSubscriptions();

      if (mounted) {
        setState(() => _googlePlaySubscriptions = subscriptions);
      }
    } catch (_) {
      // Google Play subscriptions are optional; ignore load failures.
    }
  }

  void _openPlans() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const SubscriptionPlansScreen(),
      ),
    );
  }

  Future<void> _cancelSubscription({int? googlePlaySubscriptionId}) async {
    if (googlePlaySubscriptionId != null) {
      await _cancelGooglePlaySubscription(googlePlaySubscriptionId);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No active subscription to cancel'),
        backgroundColor: AppColors.feedbackError,
      ),
    );
  }

  Future<void> _cancelGooglePlaySubscription(int subscriptionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel subscription?'),
        content: const Text(
          'Your Google Play subscription will remain active until the end of the '
          'current billing period. You can also manage it in the Play Store.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.feedbackError,
            ),
            child: const Text('Cancel subscription'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      await paymentService.cancelGooglePlaySubscription(subscriptionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Subscription cancelled successfully'),
            backgroundColor: AppColors.feedbackSuccess,
          ),
        );
        _loadSubscriptionStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to cancel subscription',
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

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
            backgroundColor:
                restored ? AppColors.feedbackSuccess : AppColors.feedbackWarning,
          ),
        );
        _loadSubscriptionStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore purchases: $e'),
            backgroundColor: AppColors.feedbackError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';
    return DateFormat('MMM d, y').format(date);
  }

  void _cancelFirstGooglePlaySubscription() {
    if (_googlePlaySubscriptions == null || _googlePlaySubscriptions!.isEmpty) {
      return;
    }
    final sub = _googlePlaySubscriptions!.first;
    final subscriptionId = sub['id'] is int
        ? sub['id'] as int
        : int.tryParse(sub['id'].toString());
    if (subscriptionId != null) {
      _cancelSubscription(googlePlaySubscriptionId: subscriptionId);
    }
  }

  bool get _hasActiveSubscription =>
      _subscriptionStatus?.isActive == true ||
      (_googlePlaySubscriptions != null && _googlePlaySubscriptions!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSettingsDetailScaffold(
      title: 'Subscription',
      action: IconButton(
        tooltip: 'Refresh',
        onPressed: _isLoading ? null : _loadSubscriptionStatus,
        icon: AppSvgIcon(
          assetPath: AppIcons.refreshCircle,
          size: 22,
          color: theme.colorScheme.onSurface,
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _subscriptionStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError && _subscriptionStatus == null) {
      return ErrorDisplayWidget(
        errorMessage: _errorMessage ?? 'Failed to load subscription status',
        onRetry: _loadSubscriptionStatus,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptionStatus,
      child: AppSettingsDetailList(
        children: [
          _buildCurrentPlanSection(context),
          if (_subscriptionStatus?.isActive == true &&
              _subscriptionStatus?.endDate != null)
            SubscriptionRenewalReminder(
              subscriptionStatus: _subscriptionStatus!,
              onCancelAutoRenewal: _cancelFirstGooglePlaySubscription,
              onChangePlan: _openPlans,
            ),
          OfflinePurchaseQueueIndicator(onRetry: _loadSubscriptionStatus),
          if (_subscriptionStatus != null) _buildDetailsSection(context),
          ..._buildGooglePlaySections(context),
          _buildManageSection(context),
          if (!_hasActiveSubscription)
            const AppSettingsSectionFootnote(
              text:
                  'Subscribe to unlock premium features like unlimited likes, '
                  'see who liked you, and more.',
            ),
          const SizedBox(height: AppSpacing.spacingMD),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanSection(BuildContext context) {
    final isActive = _subscriptionStatus?.isActive == true;
    final planName = _subscriptionStatus?.planName?.trim();
    final statusLabel = _subscriptionStatus?.status?.toUpperCase();

    return AppGroupedListSection(
      title: 'Current Plan',
      padding: AppSettingsLayout.firstSectionPadding,
      children: [
        AppGroupedInfoTile(
          label: 'Status',
          value: isActive ? 'Active subscription' : 'No active subscription',
          badge: isActive && statusLabel != null ? statusLabel : null,
        ),
        if (planName != null && planName.isNotEmpty)
          AppGroupedInfoTile(
            label: 'Plan',
            value: planName,
            showDivider: false,
          )
        else if (!isActive)
          AppGroupedInfoTile(
            label: 'Plan',
            value: 'Free',
            showDivider: false,
          ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final status = _subscriptionStatus!;
    final entries = <({String label, String value})>[
      (label: 'Start date', value: _formatDate(status.startDate)),
      (label: 'End date', value: _formatDate(status.endDate)),
      if (status.nextBillingDate != null)
        (
          label: 'Next billing',
          value: _formatDate(status.nextBillingDate),
        ),
      (label: 'Auto renew', value: status.autoRenew ? 'Yes' : 'No'),
    ];

    return AppGroupedListSection(
      title: 'Subscription Details',
      padding: AppSettingsLayout.sectionPadding,
      children: [
        for (var i = 0; i < entries.length; i++)
          AppGroupedInfoTile(
            label: entries[i].label,
            value: entries[i].value,
            showDivider: i < entries.length - 1,
          ),
      ],
    );
  }

  List<Widget> _buildGooglePlaySections(BuildContext context) {
    if (_googlePlaySubscriptions == null || _googlePlaySubscriptions!.isEmpty) {
      return const [];
    }

    return _googlePlaySubscriptions!
        .map((sub) => _buildGooglePlaySection(context, sub))
        .toList();
  }

  Widget _buildGooglePlaySection(
    BuildContext context,
    Map<String, dynamic> subscription,
  ) {
    final planName =
        subscription['plan']?['title']?.toString() ?? 'Unknown plan';
    final status = subscription['status']?.toString() ?? 'unknown';
    final billingCycle =
        subscription['billing_cycle']?.toString() ?? 'monthly';
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
    if (endDate != null && endDate.isAfter(DateTime.now())) {
      daysRemaining = endDate.difference(DateTime.now()).inDays;
    }

    final entries = <({String label, String value, String? badge})>[
      (
        label: 'Billing cycle',
        value: billingCycle.toUpperCase(),
        badge: status.toUpperCase(),
      ),
      if (startDate != null)
        (label: 'Start date', value: _formatDate(startDate), badge: null),
      if (endDate != null)
        (label: 'End date', value: _formatDate(endDate), badge: null),
      if (daysRemaining != null)
        (
          label: 'Days remaining',
          value: daysRemaining > 0 ? '$daysRemaining days' : 'Expired',
          badge: null,
        ),
    ];

    final hasCancelAction = subscriptionId != null && status == 'active';

    final children = <Widget>[
      for (var i = 0; i < entries.length; i++)
        AppGroupedInfoTile(
          label: entries[i].label,
          value: entries[i].value,
          badge: entries[i].badge,
          showDivider: hasCancelAction || i < entries.length - 1,
        ),
    ];

    if (hasCancelAction) {
      children.add(
        AppGroupedListTile(
          iconPath: AppIcons.close,
          label: 'Cancel subscription',
          subtitle: 'Managed through Google Play',
          onTap: _isCancelling
              ? () {}
              : () => _cancelSubscription(
                    googlePlaySubscriptionId: subscriptionId,
                  ),
          showDivider: false,
          trailing: _isCancelling
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : null,
        ),
      );
    }

    return AppGroupedListSection(
      title: 'Google Play · $planName',
      padding: AppSettingsLayout.sectionPadding,
      children: children,
    );
  }

  Widget _buildManageSection(BuildContext context) {
    final tiles = <Widget>[];

    if (_hasActiveSubscription) {
      tiles.add(
        AppGroupedListTile(
          iconPath: AppIcons.crown,
          label: 'Upgrade plan',
          subtitle: 'Compare plans and billing options',
          onTap: _openPlans,
        ),
      );
    } else {
      tiles.add(
        AppGroupedListTile(
          iconPath: AppIcons.crown,
          label: 'Subscribe now',
          subtitle: 'Unlock premium features',
          onTap: _openPlans,
        ),
      );
    }

    tiles.add(
      AppGroupedListTile(
        iconPath: AppIcons.refreshCircle,
        label: 'Restore purchases',
        subtitle: 'Sync purchases from Google Play',
        onTap: _isLoading ? () {} : _restorePurchases,
        showDivider: false,
        trailing: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : null,
      ),
    );

    return AppGroupedListSection(
      title: 'Manage',
      padding: AppSettingsLayout.sectionPadding,
      children: tiles,
    );
  }
}
