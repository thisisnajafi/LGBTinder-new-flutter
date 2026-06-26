import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/subscription_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/app_settings_detail.dart';
import '../../../core/widgets/premium/premium_design_system.dart';
import '../../../shared/models/api_error.dart';
import '../../../shared/services/error_handler_service.dart';
import '../../../shared/widgets/common/app_svg_icon.dart';
import '../../../widgets/error_handling/error_display_widget.dart';
import '../data/models/subscription_plan.dart';
import '../presentation/widgets/offline_purchase_queue_indicator.dart';
import '../providers/google_play_billing_provider.dart';
import '../providers/payment_providers.dart';

const _googlePlaySubscriptionsUrl =
    'https://play.google.com/store/account/subscriptions';

/// Subscription management — current plan, purchase, cancel, restore, history.
class SubscriptionManagementPage extends ConsumerStatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  ConsumerState<SubscriptionManagementPage> createState() =>
      _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState
    extends ConsumerState<SubscriptionManagementPage> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  SubscriptionStatus? _status;
  List<SubPlan> _planOptions = [];
  List<Map<String, dynamic>> _history = [];
  bool _historyExpanded = false;
  bool _historyLoading = false;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final status = await paymentService.getSubscriptionStatus();
      final plans = await paymentService.getPlans();
      final subPlans = await paymentService.getSubPlans();

      final embedded = plans.expand((p) => p.subPlans).toList();
      final merged = embedded.isNotEmpty ? embedded : subPlans;
      final premiumOptions = merged
          .where((sp) => sp.planId == 2 || sp.planId == 3)
          .toList()
        ..sort((a, b) => (a.durationDays ?? 0).compareTo(b.durationDays ?? 0));

      if (mounted) {
        setState(() {
          _status = status;
          _planOptions = premiumOptions;
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

  Future<void> _loadHistory() async {
    if (_historyLoading) return;
    setState(() => _historyLoading = true);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final result = await paymentService.getSubscriptionHistory();
      if (mounted) {
        setState(() {
          _history = result.items;
          _historyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  bool get _isPremiumActive =>
      _status?.isActive == true &&
      (_status?.tier != null && _status!.tier!.toLowerCase() != 'basid');

  bool get _isGracePeriod =>
      _status?.status?.toLowerCase() == 'grace_period';

  Future<void> _openGooglePlaySubscriptions() async {
    final uri = Uri.parse(_googlePlaySubscriptionsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _purchasePlan(SubPlan subPlan) async {
    final productId = _googlePlayProductId(subPlan.planId);
    if (productId == null) {
      _showSnack('Plan is not available for purchase', isError: true);
      return;
    }

    setState(() => _actionInProgress = true);

    try {
      final notifier = ref.read(googlePlayPurchaseProvider.notifier);
      await notifier.initiatePurchase(
        productId,
        true,
        offerId: subPlan.googleOfferId,
      );

      final state = ref.read(googlePlayPurchaseProvider);
      if (state.errorMessage != null) {
        _showSnack(state.errorMessage!, isError: true);
      }
    } catch (e) {
      _showSnack('Purchase failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _actionInProgress = true);

    try {
      final repository = ref.read(googlePlayRepositoryProvider);
      await repository.restorePurchases();
      await ref.read(subscriptionRefreshProvider).refresh();
      await _loadAll();

      if (mounted) {
        _showSnack('Purchases restored');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to restore purchases: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _showCancelSheet() async {
    final periodEnd = _status?.endDate ?? _status?.nextBillingDate;
    final periodLabel = periodEnd != null ? _formatDate(periodEnd) : 'the end of your billing period';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _CancelSubscriptionSheet(
          accessUntil: periodLabel,
          onCancelAtPeriodEnd: () async {
            Navigator.pop(sheetContext);
            await _cancelSubscription(immediately: false);
          },
          onCancelImmediately: () async {
            Navigator.pop(sheetContext);
            await _cancelSubscription(immediately: true);
          },
        );
      },
    );
  }

  Future<void> _cancelSubscription({required bool immediately}) async {
    setState(() => _actionInProgress = true);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      await paymentService.cancelLifecycleSubscription(immediately: immediately);
      await ref.read(subscriptionRefreshProvider).refresh();
      await _loadAll();

      if (mounted) {
        _showSnack(
          immediately
              ? 'Subscription cancelled immediately'
              : 'Subscription will cancel at period end',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to cancel subscription',
        );
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.feedbackError : AppColors.feedbackSuccess,
      ),
    );
  }

  String _formatDate(DateTime date) => DateFormat('MMM d, y').format(date);

  String? _googlePlayProductId(int planId) {
    switch (planId) {
      case 1:
        return 'bronze_base';
      case 2:
        return 'silver_base';
      case 3:
        return 'gold_base';
      default:
        return null;
    }
  }

  String _tierLabel(String? tier) {
    if (tier == null) return 'Free';
    switch (tier.toLowerCase()) {
      case 'silder':
        return 'Silder';
      case 'golden':
        return 'Golden';
      case 'basid':
        return 'Free';
      default:
        return tier;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSettingsDetailScaffold(
      title: 'Subscription',
      subtitle: 'Manage your premium plan',
      action: IconButton(
        tooltip: 'Refresh',
        onPressed: _isLoading ? null : _loadAll,
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
    if (_isLoading && _status == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError && _status == null) {
      return ErrorDisplayWidget(
        errorMessage: _errorMessage ?? 'Failed to load subscription',
        onRetry: _loadAll,
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadAll,
          child: AppSettingsDetailList(
            children: [
              _buildCurrentPlanCard(context),
              if (!_isPremiumActive && _planOptions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.spacingLG),
                _buildPlanOptionsSection(context),
              ],
              if (_isPremiumActive) ...[
                const SizedBox(height: AppSpacing.spacingLG),
                _buildActionsSection(context),
              ],
              const SizedBox(height: AppSpacing.spacingMD),
              OfflinePurchaseQueueIndicator(onRetry: _loadAll),
              const SizedBox(height: AppSpacing.spacingLG),
              _buildHistorySection(context),
              const SizedBox(height: AppSpacing.spacingXL),
            ],
          ),
        ),
        if (_actionInProgress)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentPlanCard(BuildContext context) {
    final theme = Theme.of(context);
    final tier = _status?.tier;
    final planName = _status?.planName ?? _tierLabel(tier);
    final periodEnd = _status?.endDate ?? _status?.nextBillingDate;

    if (!_isPremiumActive) {
      return PremiumSettingsGroup(
        title: 'Current plan',
        children: [
          PremiumInfoRow(label: 'Plan', value: 'Free Plan'),
          PremiumSettingsTile(
            iconPath: AppIcons.crown,
            title: 'Upgrade to premium',
            subtitle: 'Unlock unlimited likes, see who liked you, and more',
            accent: theme.colorScheme.primary,
            onTap: () {
              if (_planOptions.isNotEmpty) {
                _purchasePlan(_planOptions.first);
              }
            },
          ),
        ],
      );
    }

    return PremiumSettingsGroup(
      title: 'Current plan',
      children: [
        PremiumInfoRow(
          label: 'Tier',
          value: planName,
          badge: _status?.status?.toUpperCase(),
        ),
        if (periodEnd != null)
          PremiumInfoRow(
            label: 'Next billing',
            value: _formatDate(periodEnd),
          ),
        if (_status?.cancelAtPeriodEnd == true && periodEnd != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingMD,
              vertical: AppSpacing.spacingSM,
            ),
            child: Text(
              'Cancels on ${_formatDate(periodEnd)}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.feedbackWarning,
              ),
            ),
          ),
        if (_isGracePeriod)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingMD,
              vertical: AppSpacing.spacingSM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment failed — update your payment method in Google Play',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.feedbackError,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                TextButton.icon(
                  onPressed: _openGooglePlaySubscriptions,
                  icon: AppSvgIcon(
                    assetPath: AppIcons.playCircle,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: const Text('Manage in Google Play'),
                ),
              ],
            ),
          ),
        if (!_isGracePeriod)
          PremiumInfoRow(
            label: 'Auto renew',
            value: _status?.autoRenew == true && !_status!.cancelAtPeriodEnd
                ? 'Yes'
                : 'No',
          ),
      ],
    );
  }

  Widget _buildPlanOptionsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingMD),
          child: Text(
            'Choose a plan',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.spacingSM),
        ..._planOptions.map((subPlan) {
          final isYearly = (subPlan.durationDays ?? 0) >= 365;
          final tierName = subPlan.planId == 3 ? 'Golden' : 'Silder';

          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingMD,
              vertical: AppSpacing.spacingXS,
            ),
            child: InkWell(
              onTap: _actionInProgress ? null : () => _purchasePlan(subPlan),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$tierName ${subPlan.durationLabel}',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (isYearly)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Best value',
                              style: AppTypography.labelSmall.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      '\$${subPlan.price.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (subPlan.description != null) ...[
                      const SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        subPlan.description!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    final theme = Theme.of(context);

    return PremiumSettingsGroup(
      title: 'Manage subscription',
      children: [
        PremiumSettingsTile(
          iconPath: AppIcons.close,
          title: 'Cancel subscription',
          subtitle: 'Stop auto-renewal or cancel immediately',
          destructive: true,
          onTap: _actionInProgress ? () {} : _showCancelSheet,
        ),
        PremiumSettingsTile(
          iconPath: AppIcons.refreshCircle,
          title: 'Restore purchases',
          subtitle: 'Recover a subscription from Google Play',
          accent: theme.colorScheme.primary,
          onTap: _actionInProgress ? () {} : _restorePurchases,
        ),
        PremiumSettingsTile(
          iconPath: AppIcons.playCircle,
          title: 'Manage in Google Play',
          subtitle: 'Update payment method or change plan',
          accent: theme.colorScheme.primary,
          onTap: _openGooglePlaySubscriptions,
        ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    final theme = Theme.of(context);

    return PremiumSettingsGroup(
      title: 'Subscription history',
      children: [
        PremiumSettingsTile(
          iconPath: AppIcons.documentText,
          title: _historyExpanded ? 'Hide history' : 'Show history',
          subtitle: _history.isEmpty && !_historyExpanded
              ? 'Tap to load past subscriptions'
              : '${_history.length} record(s)',
          accent: theme.colorScheme.onSurfaceVariant,
          onTap: () async {
            final expand = !_historyExpanded;
            setState(() => _historyExpanded = expand);
            if (expand && _history.isEmpty) {
              await _loadHistory();
            }
          },
        ),
        if (_historyExpanded) ...[
          if (_historyLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              child: Text('No subscription history yet'),
            )
          else
            ..._history.map(_buildHistoryRow),
        ],
      ],
    );
  }

  Widget _buildHistoryRow(Map<String, dynamic> item) {
    final tier = item['tier']?.toString();
    final status = item['status']?.toString() ?? 'unknown';
    final provider = item['provider']?.toString() ?? '';
    final started = item['started_at']?.toString();
    final ended = item['ended_at']?.toString();
    final startedDate =
        started != null ? DateTime.tryParse(started) : null;
    final endedDate = ended != null ? DateTime.tryParse(ended) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingMD,
        vertical: AppSpacing.spacingSM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSvgIcon(
            assetPath: provider == 'google_play'
                ? AppIcons.playCircle
                : AppIcons.card,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_tierLabel(tier)} · ${status.replaceAll('_', ' ')}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (startedDate != null)
                  Text(
                    'Started ${_formatDate(startedDate)}'
                    '${endedDate != null ? ' · Ended ${_formatDate(endedDate)}' : ''}',
                    style: AppTypography.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelSubscriptionSheet extends StatefulWidget {
  const _CancelSubscriptionSheet({
    required this.accessUntil,
    required this.onCancelAtPeriodEnd,
    required this.onCancelImmediately,
  });

  final String accessUntil;
  final Future<void> Function() onCancelAtPeriodEnd;
  final Future<void> Function() onCancelImmediately;

  @override
  State<_CancelSubscriptionSheet> createState() =>
      _CancelSubscriptionSheetState();
}

class _CancelSubscriptionSheetState extends State<_CancelSubscriptionSheet> {
  final _confirmController = TextEditingController();
  bool _showImmediateConfirm = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.spacingLG,
        right: AppSpacing.spacingLG,
        top: AppSpacing.spacingLG,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.spacingLG,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Cancel subscription?', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.spacingSM),
          Text(
            'Your premium access continues until ${widget.accessUntil}.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.spacingLG),
          FilledButton(
            onPressed: () => widget.onCancelAtPeriodEnd(),
            child: const Text('Cancel at period end'),
          ),
          const SizedBox(height: AppSpacing.spacingSM),
          OutlinedButton(
            onPressed: () {
              setState(() => _showImmediateConfirm = true);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.feedbackError,
            ),
            child: const Text('Cancel immediately'),
          ),
          if (_showImmediateConfirm) ...[
            const SizedBox(height: AppSpacing.spacingMD),
            Text(
              'Type CANCEL to confirm immediate cancellation',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.spacingSM),
            TextField(
              controller: _confirmController,
              decoration: const InputDecoration(
                hintText: 'CANCEL',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: AppSpacing.spacingSM),
            FilledButton(
              onPressed: _confirmController.text.trim().toUpperCase() == 'CANCEL'
                  ? () => widget.onCancelImmediately()
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.feedbackError,
              ),
              child: const Text('Confirm immediate cancellation'),
            ),
          ],
        ],
      ),
    );
  }
}
