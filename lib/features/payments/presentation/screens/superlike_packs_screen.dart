// Screen: Superlike Packs — purchase flow aligned with SubscriptionPlansScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/session_cache_providers.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../shared/analytics/app_event_tracker.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../shared/services/error_handler_service.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_subscription_plans.dart';
import '../../data/models/superlike_pack.dart';
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
      final service = ref.read(superlikePackServiceProvider);
      await service.purchasePack(
        PurchaseSuperlikePackRequest(packId: pack.id),
      );

      ref.invalidate(availableSuperlikePacksProvider);
      ref.invalidate(userSuperlikePacksProvider);
      ref.read(planLimitsServiceProvider).clearCache();
      ref.read(planLimitsProvider.notifier).clearCache();
      await ref.read(planLimitsProvider.notifier).refreshFromApi();
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
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
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

    return AppPageScaffold(
      title: 'Superlikes',
      showBackButton: true,
      backgroundColor: backgroundColor,
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
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(availableSuperlikePacksProvider);
                      },
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.spacingLG,
                          AppSpacing.spacingLG,
                          AppSpacing.spacingLG,
                          AppSpacing.spacingSM,
                        ),
                        children: [
                          _buildHeader(textColor, secondaryTextColor),
                          _buildBalanceCard(remaining),
                          _buildPaymentBadge(borderColor),
                          SizedBox(height: AppSpacing.spacingXL),
                          Text(
                            'Choose a pack',
                            style: AppTypography.h3.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: AppSpacing.spacingMD),
                          ...packs.map(
                            (pack) => _buildPackCard(
                              pack,
                              surfaceColor,
                              borderColor,
                              textColor,
                              secondaryTextColor,
                              isDark,
                            ),
                          ),
                          SizedBox(height: AppSpacing.spacingMD),
                          Text(
                            'Superlikes never expire. Use them whenever you find someone special.',
                            style: AppTypography.caption.copyWith(
                              color: secondaryTextColor,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
        padding: EdgeInsets.all(AppSpacing.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(
              assetPath: AppIcons.getIconPath('star'),
              size: 64,
              color: secondaryTextColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            Text(
              'No Packs Available',
              style: AppTypography.h3.copyWith(color: textColor),
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
                assetPath: AppIcons.getIconPath('card'),
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

  Widget _buildPackCard(
    SuperlikePack pack,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final isSelected = _selectedPackId == pack.id;
    final accent = pack.isPopular ? AppColors.accentPink : AppColors.accentPurple;
    final cardBg = isSelected
        ? (isDark ? accent.withValues(alpha: 0.14) : accent.withValues(alpha: 0.08))
        : surfaceColor;
    final border = isSelected ? accent : borderColor;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingLG),
      child: Material(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          side: BorderSide(color: border, width: isSelected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _selectedPackId = pack.id),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Radio<int>(
                      value: pack.id,
                      groupValue: _selectedPackId,
                      onChanged: (value) =>
                          setState(() => _selectedPackId = value),
                      activeColor: accent,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pack.name,
                                  style: AppTypography.h3.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (pack.isPopular)
                                Container(
                                  padding: EdgeInsets.symmetric(
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
                            SizedBox(height: AppSpacing.spacingXS),
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
                SizedBox(height: AppSpacing.spacingMD),
                Row(
                  children: [
                    AppSvgIcon(
                      assetPath: AppIcons.getIconPath('star', style: 'bold'),
                      size: 22,
                      color: accent,
                    ),
                    SizedBox(width: AppSpacing.spacingSM),
                    Text(
                      '${pack.superlikeCount} Superlikes',
                      style: AppTypography.body.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
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
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      ),
                      child: Text(
                        _formatPrice(pack.price, pack.currency),
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
