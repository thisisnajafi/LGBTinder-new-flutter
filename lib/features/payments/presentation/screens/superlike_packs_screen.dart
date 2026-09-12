// Screen: Superlike Packs — purchase flow aligned with SubscriptionPlansScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/cache/session_cache_providers.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_list_view.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../../../shared/analytics/app_event_tracker.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../shared/services/error_handler_service.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_subscription_plans.dart';
import '../../data/models/superlike_pack.dart';
import '../../data/services/plan_limits_service.dart';
import '../../providers/google_play_billing_provider.dart';
import '../../providers/payment_providers.dart';

/// Full-screen superlike pack purchase — mirrors subscription plans UX.
class SuperlikePacksScreen extends ConsumerStatefulWidget {
  const SuperlikePacksScreen({super.key});

  @override
  ConsumerState<SuperlikePacksScreen> createState() =>
      _SuperlikePacksScreenState();
}

class _SuperlikePacksScreenState extends ConsumerState<SuperlikePacksScreen> {
  int? _selectedPackId;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appEventTrackerProvider).track(
            'superlike_packs_view',
            meta: {'screen': 'superlike_packs'},
          );
    });
  }

  SuperlikePack? get _selectedPack {
    if (_selectedPackId == null) return null;
    final packs = ref.read(availableSuperlikePacksProvider).valueOrNull ?? [];
    for (final pack in packs) {
      if (pack.id == _selectedPackId) return pack;
    }
    return null;
  }

  bool _isBestValuePack(SuperlikePack pack, List<SuperlikePack> packs) {
    SuperlikePack? best;
    double? bestUnit;
    for (final item in packs) {
      if (item.superlikeCount <= 0 || item.price <= 0) continue;
      final unit = item.price / item.superlikeCount;
      if (bestUnit == null || unit < bestUnit) {
        bestUnit = unit;
        best = item;
      }
    }
    return best?.id == pack.id;
  }

  String _formatPrice(double price, String currency) {
    final symbol =
        currency.toUpperCase() == 'USD' ? '\$' : currency.toUpperCase();
    final decimals = price % 1 == 0 ? 0 : 2;
    return '$symbol${price.toStringAsFixed(decimals)}';
  }

  Future<void> _handlePurchase() async {
    final pack = _selectedPack;
    if (pack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pack'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    setState(() => _isPurchasing = true);

    try {
      final productId = pack.resolvedGoogleProductId;
      if (productId == null) {
        throw Exception('This pack is not available for in-app purchase');
      }

      final billing = ref.read(googlePlayBillingServiceProvider);
      final outcome = billing.waitForPurchaseOutcome(productId);
      final launched = await billing.purchaseConsumableProduct(productId);
      if (!launched) {
        throw Exception('Could not start Google Play purchase');
      }

      final status = await outcome;
      if (status == PurchaseStatus.canceled) {
        return;
      }
      if (status != PurchaseStatus.purchased && status != PurchaseStatus.restored) {
        throw Exception('Purchase did not complete');
      }

      ref.invalidate(availableSuperlikePacksProvider);
      ref.invalidate(userSuperlikePacksProvider);
      ref.read(planLimitsServiceProvider).clearCache();
      ref.read(planLimitsProvider.notifier).clearCache();
      await ref.read(planLimitsProvider.notifier).refresh();
      final remaining = ref.read(superlikesRemainingProvider);
      if (remaining != null) {
        await ref
            .read(sessionDataCacheServiceProvider)
            .setSuperlikesRemaining(remaining);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Superlikes added to your account!'),
          backgroundColor: AppColors.feedbackSuccess,
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiError catch (e) {
      if (!mounted) return;
      ErrorHandlerService.showErrorSnackBar(
        context,
        e,
        customMessage: 'Failed to purchase pack',
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandlerService.handleError(
        context,
        e,
        customMessage: 'Failed to purchase pack',
      );
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    final packsAsync = ref.watch(availableSuperlikePacksProvider);
    final remaining = ref.watch(superlikesRemainingProvider);

    return PremiumDetailScaffold(
      title: 'Superlikes',
      onBack: () => Navigator.of(context).maybePop(),
      body: packsAsync.when(
        loading: () => const SkeletonSubscriptionPlans(),
        error: (error, _) => ErrorDisplayWidget(
          errorMessage: error.toString(),
          onRetry: () => ref.invalidate(availableSuperlikePacksProvider),
        ),
        data: (packs) => packs.isEmpty
            ? _buildEmptyState(textColor, secondaryTextColor)
            : Column(
                children: [
                  Expanded(
                    child: PremiumRefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(availableSuperlikePacksProvider);
                      },
                      child: AppListView.builder(
                        physics: AppScroll.bouncing,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.spacingLG,
                          AppSpacing.spacingLG,
                          AppSpacing.spacingLG,
                          AppSpacing.spacingSM,
                        ),
                        itemCount: packs.length + 2,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(textColor, secondaryTextColor),
                                _buildBalanceCard(remaining),
                                _buildPaymentBadge(borderColor),
                                const SizedBox(height: AppSpacing.spacingXL),
                                Text(
                                  'Choose a pack',
                                  style: AppTypography.h3.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.spacingMD),
                              ],
                            );
                          }
                          if (index == packs.length + 1) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.spacingMD,
                              ),
                              child: Text(
                                'Superlikes never expire. Use them whenever you find someone special.',
                                style: AppTypography.caption.copyWith(
                                  color: secondaryTextColor,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return _SuperlikePackCard(
                            pack: packs[index - 1],
                            selectedPackId: _selectedPackId,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                            isDark: isDark,
                            isBestValue: _isBestValuePack(
                              packs[index - 1],
                              packs,
                            ),
                            formatPrice: _formatPrice,
                            onSelected: (id) =>
                                setState(() => _selectedPackId = id),
                          );
                        },
                      ),
                    ),
                  ),
                  _buildPurchaseBar(isDark, textColor, secondaryTextColor),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color secondaryTextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PremiumPageHeader.horizontalPadding,
        ),
        child: PremiumShell(
          margin: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentViolet.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: AppIcons.getIconPath('star', style: 'bold'),
                    size: 32,
                    color: AppColors.accentViolet,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.spacingMD),
              Text(
                'No Packs Available',
                style: AppTypography.h3.copyWith(color: textColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.spacingSM),
              Text(
                'Superlike packs are not available at the moment. Check back soon.',
                style: AppTypography.body.copyWith(color: secondaryTextColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Get More Superlikes',
          style: AppTypography.h1.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpacing.spacingSM),
        Text(
          'Stand out and get noticed. Superlikes tell someone you are genuinely interested.',
          style: AppTypography.body.copyWith(
            color: secondaryTextColor,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(int? remaining) {
    return Container(
      margin: EdgeInsets.only(top: AppSpacing.spacingLG),
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppSvgIcon(
                assetPath: AppIcons.getIconPath('star', style: 'bold'),
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your balance',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  '${remaining ?? '—'} Superlikes',
                  style: AppTypography.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(Color borderColor) {
    return Consumer(
      builder: (context, ref, _) {
        final paymentSystem = ref.watch(activePaymentSystemProvider);
        return Container(
          margin: EdgeInsets.only(top: AppSpacing.spacingLG),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingMD,
            vertical: AppSpacing.spacingSM,
          ),
          decoration: BoxDecoration(
            color: AppColors.accentPink.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            border: Border.all(
              color: AppColors.accentPink.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              AppSvgIcon(
                assetPath: AppIcons.card,
                size: 20,
                color: AppColors.accentPink,
              ),
              SizedBox(width: AppSpacing.spacingSM),
              Text(
                'Payment via ${paymentSystem.displayName}',
                style: AppTypography.body.copyWith(
                  color: AppColors.accentPink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPurchaseBar(
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final pack = _selectedPack;
    final summary = pack != null
        ? '${pack.name} · ${pack.superlikeCount} Superlikes · ${_formatPrice(pack.price, pack.currency)}'
        : 'Select a pack to continue';

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.spacingLG,
        AppSpacing.spacingMD,
        AppSpacing.spacingLG,
        AppSpacing.spacingLG,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.borderMediumDark
                : AppColors.borderMediumLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              summary,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.spacingSM),
            GradientButton(
              text: _isPurchasing ? 'Processing...' : 'Purchase Superlikes',
              onPressed: _isPurchasing || pack == null ? null : _handlePurchase,
              isFullWidth: true,
              isLoading: _isPurchasing,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuperlikePackCard extends StatelessWidget {
  const _SuperlikePackCard({
    required this.pack,
    required this.selectedPackId,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.isDark,
    required this.isBestValue,
    required this.formatPrice,
    required this.onSelected,
  });

  final SuperlikePack pack;
  final int? selectedPackId;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color secondaryTextColor;
  final bool isDark;
  final bool isBestValue;
  final String Function(double price, String currency) formatPrice;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedPackId == pack.id;
    final showBestValue = isBestValue || pack.isPopular;
    final accent =
        pack.isPopular ? AppColors.accentPink : AppColors.accentPurple;
    final cardBg = isSelected
        ? (isDark ? accent.withValues(alpha: 0.14) : accent.withValues(alpha: 0.08))
        : surfaceColor;
    final border = isSelected ? accent : borderColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacingLG),
      child: Material(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          side: BorderSide(color: border, width: isSelected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSelected(pack.id),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Radio<int>(
                      value: pack.id,
                      groupValue: selectedPackId,
                      onChanged: (value) {
                        if (value != null) onSelected(value);
                      },
                      activeColor: accent,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AppText(
                                  pack.name,
                                  style: AppTypography.h3.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              if (showBestValue)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.spacingSM,
                                    vertical: AppSpacing.spacingXS,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.brandGradient,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.radiusSM,
                                    ),
                                  ),
                                  child: Text(
                                    'BEST VALUE',
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (pack.description != null &&
                              pack.description!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.spacingXS),
                            Text(
                              pack.description!,
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
                const SizedBox(height: AppSpacing.spacingMD),
                Row(
                  children: [
                    AppSvgIcon(
                      assetPath: AppIcons.getIconPath('star', style: 'bold'),
                      size: 22,
                      color: accent,
                    ),
                    const SizedBox(width: AppSpacing.spacingSM),
                    Text(
                      '${pack.superlikeCount} Superlikes',
                      style: AppTypography.body.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacingMD,
                        vertical: AppSpacing.spacingSM,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? AppColors.brandGradient
                            : LinearGradient(
                                colors: [
                                  accent.withValues(alpha: 0.15),
                                  accent.withValues(alpha: 0.08),
                                ],
                              ),
                        borderRadius:
                            BorderRadius.circular(AppRadius.radiusMD),
                      ),
                      child: Text(
                        formatPrice(pack.price, pack.currency),
                        style: AppTypography.body.copyWith(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
