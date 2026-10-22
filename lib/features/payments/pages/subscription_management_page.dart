import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../../routes/app_router.dart';
import '../../../shared/models/user_tier.dart';
import '../../../shared/services/error_handler_service.dart';
import '../../../widgets/error_handling/error_display_widget.dart';
import '../data/models/subscription_plan.dart';
import '../presentation/widgets/offline_purchase_queue_indicator.dart';
import '../providers/google_play_billing_provider.dart';
import '../providers/payment_providers.dart';
import '../../../core/responsive/responsive.dart';

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
  bool _historyHasMore = true;
  int _historyPage = 1;
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
      // Plan ids: 1 = Basic, 2 = Premium (legacy "Silver"), 3 = Gold.
      final premiumOptions = merged
          .where((sp) => userTierFromPlanId(sp.planId) != null)
          .toList()
        ..sort((a, b) {
          final byTier = (a.planId ?? 0).compareTo(b.planId ?? 0);
          if (byTier != 0) return byTier;
          return (a.durationDays ?? 0).compareTo(b.durationDays ?? 0);
        });

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

  List<Map<String, dynamic>> _historyFromCurrentStatus() {
    final status = _status;
    if (status == null || !status.isActive) return const [];
    return [
      {
        'id': status.planId ?? 0,
        'plan_name': planDisplayName(status.tier ?? status.planName),
        'tier': status.tier,
        'status': status.status ?? 'active',
        'provider': status.provider,
        'started_at': status.startDate?.toIso8601String(),
        'ended_at': null,
        'amount': null,
        'currency': null,
      },
    ];
  }

  Future<void> _loadHistory({bool more = false}) async {
    if (_historyLoading) return;
    if (more && !_historyHasMore) return;
    setState(() => _historyLoading = true);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final page = more ? _historyPage : 1;
      final result = await paymentService.getSubscriptionHistory(page: page);
      if (!mounted) return;
      final loaded = (more ? _history.length : 0) + result.items.length;
      final hasMore = _subscriptionHistoryHasMore(
        result.pagination,
        page,
        result.items.length,
        loaded,
      );
      final rows = result.items.isNotEmpty
          ? result.items
          : _historyFromCurrentStatus();
      setState(() {
        if (more) {
          _history = [..._history, ...result.items];
        } else {
          _history = rows;
        }
        _historyPage = page + 1;
        _historyHasMore = hasMore;
        _historyLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  bool _subscriptionHistoryHasMore(
    Map<String, dynamic> pagination,
    int page,
    int itemCount,
    int loadedCount,
  ) {
    final hasMore = pagination['has_more'] ?? pagination['hasMore'];
    if (hasMore is bool) return hasMore;
    final last = pagination['last_page'] ?? pagination['lastPage'];
    if (last is int) return page < last;
    if (last is num) return page < last.toInt();
    final total = pagination['total'];
    if (total is int) return loadedCount < total;
    return itemCount >= 20;
  }

  /// Current paid tier, or null for Free. Reads the same global subscription
  /// state the Compare tiers page uses (API `meta.subscription`), and falls
  /// back to `/subscriptions/status` so the two pages always agree.
  UserTier? get _currentTier {
    final global = ref.watch(subscriptionProvider);
    if (global != null && global.isActive) return global.tier;
    final status = _status;
    if (status != null && status.isActive) {
      final raw = status.tier?.toLowerCase().trim() ?? '';
      if (raw.isNotEmpty && raw != 'free' && raw != 'none') {
        return userTierFromApiKey(raw);
      }
      return userTierFromPlanId(status.planId) ??
          userTierFromPlan(planId: status.planId, planName: status.planName);
    }
    return null;
  }

  bool get _hasPaidPlan => _currentTier != null;

  bool get _isGold => _currentTier == UserTier.golden;

  /// Upgrade options above the current tier (Gold has none).
  List<SubPlan> get _upgradeOptions {
    final current = _currentTier;
    return _planOptions.where((sp) {
      final tier = userTierFromPlanId(sp.planId);
      if (tier == null) return false;
      return current == null || tier.level > current.level;
    }).toList();
  }

  // Kept for the actions section (cancel / restore / manage) visibility.
  bool get _isPremiumActive => _hasPaidPlan;

  bool get _isGracePeriod =>
      _status?.status?.toLowerCase() == 'grace_period';

  Future<void> _openGooglePlaySubscriptions() async {
    final uri = Uri.parse(_googlePlaySubscriptionsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _purchasePlan(SubPlan subPlan) async {
    final productId = _googlePlayProductId(subPlan);
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
      if (state.isSuccess) {
        await ref.read(subscriptionRefreshProvider).refresh();
        await _loadAll();
        if (mounted) _showSnack('Subscription updated');
      } else if (state.errorMessage != null) {
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

  String? _googlePlayProductId(SubPlan subPlan) {
    final fromSub = subPlan.googleProductId?.trim();
    if (fromSub != null && fromSub.isNotEmpty) return fromSub;
    return null;
  }

  String _tierLabel(String? tier) => planDisplayName(tier);

  @override
  Widget build(BuildContext context) {
    return AppSettingsDetailScaffold(
      title: 'Subscription',
      subtitle: 'Manage your premium plan',
      action: CompactHeaderIconButton(
        iconPath: AppIcons.refresh,
        semanticLabel: 'Refresh',
        tooltip: 'Refresh',
        onPressed: _isLoading ? null : _loadAll,
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
        PremiumRefreshIndicator(
          onRefresh: _loadAll,
          child: AppSettingsDetailList(
            children: [
              _buildCurrentPlanCard(context),
              if (_upgradeOptions.isNotEmpty) ...[
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
    final current = _currentTier;
    final planName = current?.displayLabel ?? 'Free';
    final periodEnd = _status?.endDate ??
        _status?.nextBillingDate ??
        ref.watch(subscriptionProvider)?.expiresAt;

    if (current == null) {
      return PremiumSettingsGroup(
        title: 'Current plan',
        children: [
          const PremiumInfoRow(label: 'Plan', value: 'Free'),
          PremiumSettingsTile(
            iconPath: AppIcons.crown,
            title: 'Upgrade your plan',
            subtitle:
                'Basic unlocks unlimited chat. Premium adds voice calls and see who liked you. Gold unlocks everything.',
            accent: theme.colorScheme.primary,
            onTap: () => context.push(AppRoutes.tierComparison),
          ),
        ],
      );
    }

    return PremiumSettingsGroup(
      title: 'Current plan',
      children: [
        PremiumInfoRow(
          label: 'Plan',
          value: planName,
          badge: (_status?.status ?? 'active').toUpperCase(),
        ),
        if (_isGold)
          const PremiumInfoRow(
            label: 'Benefits',
            value: 'Every feature unlocked',
          )
        else
          PremiumSettingsTile(
            iconPath: AppIcons.crown,
            title: current == UserTier.silder
                ? 'Upgrade to Gold'
                : 'Upgrade to Premium or Gold',
            subtitle: current == UserTier.silder
                ? 'Add video calls, AI matching and more superlikes'
                : 'Add voice calls, see who liked you, advanced filters and more',
            accent: Theme.of(context).colorScheme.primary,
            onTap: () => context.push(AppRoutes.tierComparison),
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
    final options = _upgradeOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingMD),
          child: Text(
            _hasPaidPlan ? 'Upgrade options' : 'Choose a plan',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.spacingSM),
        ...options.map((subPlan) {
          final isYearly = (subPlan.durationDays ?? 0) >= 365;
          final tierName =
              userTierFromPlanId(subPlan.planId)?.displayLabel ?? 'Premium';

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
            child: SizedBox(
              width: double.infinity,
              child: PremiumShell(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: ValueKey('sub_plan_option_${subPlan.id}'),
                    onTap: _actionInProgress ? null : () => _purchasePlan(subPlan),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.spacingLG),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: AppSpacing.spacingSM,
                                  runSpacing: AppSpacing.spacingXS,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '$tierName · ${subPlan.durationLabel}',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
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
                                if (subPlan.description != null) ...[
                                  const SizedBox(height: AppSpacing.spacingXS),
                                  AppText(
                                    subPlan.description!,
                                    style: theme.textTheme.bodySmall,
                                    maxLines: 3,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.spacingMD),
                          Text(
                            '\$${subPlan.price.toStringAsFixed(2)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
            ...[
              ..._history.map(_buildHistoryRow),
              if (_historyHasMore)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.spacingMD,
                  ),
                  child: Center(
                    child: TextButton(
                      onPressed: _historyLoading
                          ? null
                          : () => _loadHistory(more: true),
                      child: const Text('Load more'),
                    ),
                  ),
                ),
            ],
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
                AppText(
                  '${_tierLabel(tier)} · ${status.replaceAll('_', ' ')}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                ),
                if (startedDate != null)
                  AppText(
                    'Started ${_formatDate(startedDate)}'
                    '${endedDate != null ? ' · Ended ${_formatDate(endedDate)}' : ''}',
                    style: AppTypography.bodySmall,
                    maxLines: 2,
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
