import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/session_cache_providers.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/startup_cache_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/widgets/app_action_bottom_sheet.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../features/payments/data/models/superlike_pack.dart';
import '../../features/payments/data/services/plan_limits_service.dart';
import '../../features/payments/providers/payment_providers.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/loading/skeleton_loading.dart';

/// Opens the superlike packs purchase bottom sheet.
Future<void> showSuperlikePacksSheet(
  BuildContext context, {
  String? headerMessage,
  bool fetchCountInBackground = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => AppBottomSheetShell(
      showCancel: true,
      body: SuperlikePacksSheet(
        headerMessage: headerMessage,
        fetchCountInBackground: fetchCountInBackground,
      ),
    ),
  );
}

class SuperlikePacksSheet extends ConsumerStatefulWidget {
  const SuperlikePacksSheet({
    super.key,
    this.headerMessage,
    this.fetchCountInBackground = false,
  });

  final String? headerMessage;
  final bool fetchCountInBackground;

  @override
  ConsumerState<SuperlikePacksSheet> createState() =>
      _SuperlikePacksSheetState();
}

class _SuperlikePacksSheetState extends ConsumerState<SuperlikePacksSheet> {
  int? _selectedPackId;
  bool _isPurchasing = false;
  bool _isLoadingCount = false;

  @override
  void initState() {
    super.initState();
    if (widget.fetchCountInBackground) {
      _isLoadingCount = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_fetchRemainingCount());
      });
    }
  }

  String _formatPrice(double price, String currency) {
    final symbol = currency.toUpperCase() == 'USD' ? '\$' : currency.toUpperCase();
    return '$symbol${price.toStringAsFixed(2)}';
  }

  Future<void> _fetchRemainingCount() async {
    try {
      final planLimitsService = ref.read(planLimitsServiceProvider);
      final limits = await planLimitsService.getPlanLimits(forceRefresh: true);
      final remaining = limits.effectiveSuperlikeInfo.totalRemaining;
      final sessionCache = ref.read(sessionDataCacheServiceProvider);
      await sessionCache.setSuperlikesRemaining(remaining);
      ref.read(superlikesRemainingProvider.notifier).setCount(remaining);
      ref.invalidate(planLimitsProvider);
    } catch (e, stack) {
      AppLogger.error(
        'Background superlike count fetch failed',
        tag: 'SuperlikePacksSheet',
        error: e,
        stackTrace: stack,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingCount = false);
      }
    }
  }

  Future<void> _handlePurchase() async {
    if (_selectedPackId == null) return;

    setState(() => _isPurchasing = true);
    try {
      final superlikeService = ref.read(superlikePackServiceProvider);
      await superlikeService.purchasePack(
        PurchaseSuperlikePackRequest(packId: _selectedPackId!),
      );

      await ref.read(startupCacheServiceProvider).primeCache();
      ref.invalidate(availableSuperlikePacksProvider);
      ref.invalidate(planLimitsProvider);
      ref.invalidate(subscriptionStatusProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Superlike pack purchased successfully!'),
            backgroundColor: AppColors.feedbackSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to purchase pack',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to purchase pack',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  List<SuperlikePack> _resolvePacks() {
    final cached =
        ref.read(sessionDataCacheServiceProvider).getSuperlikePacksSync();
    if (cached != null && cached.isNotEmpty) return cached;
    return ref.watch(availableSuperlikePacksProvider).valueOrNull ??
        const <SuperlikePack>[];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    final remotePacksAsync = ref.watch(availableSuperlikePacksProvider);
    final packs = _resolvePacks();
    final isLoadingPacks =
        packs.isEmpty && remotePacksAsync.isLoading && !_isLoadingCount;

    return AppBottomSheetCard(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.spacingLG,
                AppSpacing.spacingMD,
                AppSpacing.spacingLG,
                AppSpacing.spacingSM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppSvgIcon(
                        assetPath: AppIcons.star,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: AppSpacing.spacingSM),
                      Expanded(
                        child: Text(
                          'Get Superlikes',
                          style: AppTypography.titleLarge.copyWith(
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                    if (widget.headerMessage != null) ...[
                      SizedBox(height: AppSpacing.spacingSM),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(AppSpacing.spacingMD),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                        ),
                        child: Text(
                          widget.headerMessage!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                    if (_isLoadingCount) ...[
                      SizedBox(height: AppSpacing.spacingMD),
                      LinearProgressIndicator(
                        color: theme.colorScheme.primary,
                        backgroundColor: borderColor,
                      ),
                    ],
                  ],
                ),
              ),
              Flexible(
                child: isLoadingPacks
                    ? Padding(
                        padding: EdgeInsets.all(AppSpacing.spacingLG),
                        child: Column(
                          children: List.generate(
                            3,
                            (_) => Padding(
                              padding: EdgeInsets.only(
                                bottom: AppSpacing.spacingSM,
                              ),
                              child: SkeletonLoading(
                                height: 72,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.radiusMD,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : packs.isEmpty
                        ? Padding(
                            padding: EdgeInsets.all(AppSpacing.spacingLG),
                            child: Text(
                              'Superlike packs are not available at the moment.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.spacingLG,
                            ),
                            itemCount: packs.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: AppSpacing.spacingSM),
                            itemBuilder: (context, index) {
                              final pack = packs[index];
                              final selected = _selectedPackId == pack.id;
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => setState(
                                    () => _selectedPackId = pack.id,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.radiusMD,
                                  ),
                                  child: Container(
                                    padding:
                                        EdgeInsets.all(AppSpacing.spacingMD),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? theme.colorScheme.primary
                                              .withValues(alpha: 0.1)
                                          : surface,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.radiusMD,
                                      ),
                                      border: Border.all(
                                        color: selected
                                            ? theme.colorScheme.primary
                                            : borderColor,
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pack.name,
                                                style: AppTypography.titleMedium
                                                    .copyWith(
                                                  color: textPrimary,
                                                ),
                                              ),
                                              SizedBox(
                                                height: AppSpacing.spacingXS,
                                              ),
                                              Text(
                                                '${pack.superlikeCount} Superlikes',
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                  color: textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _formatPrice(
                                            pack.price,
                                            pack.currency,
                                          ),
                                          style: AppTypography.labelMedium
                                              .copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              Padding(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: GradientButton(
                  onPressed: _isPurchasing || _selectedPackId == null
                      ? null
                      : _handlePurchase,
                  isLoading: _isPurchasing,
                  text: 'Purchase Pack',
                ),
              ),
            ],
          ),
        ),
    );
  }
}
