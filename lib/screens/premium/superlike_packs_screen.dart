// Screen: SuperlikePacksScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/error_handling/error_display_widget.dart';
import '../../widgets/loading/skeleton_loading.dart';
import '../../features/payments/providers/payment_providers.dart';
import '../../features/payments/data/models/superlike_pack.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';

/// Superlike packs screen - Purchase superlike packs
class SuperlikePacksScreen extends ConsumerStatefulWidget {
  const SuperlikePacksScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SuperlikePacksScreen> createState() => _SuperlikePacksScreenState();
}

class _SuperlikePacksScreenState extends ConsumerState<SuperlikePacksScreen> {
  int? _selectedPackId;
  bool _isPurchasing = false;
  int _totalSuperlikes = 0;

  @override
  void initState() {
    super.initState();
    _loadUserSuperlikes();
  }

  Future<void> _loadUserSuperlikes() async {
    try {
      final superlikeService = ref.read(superlikePackServiceProvider);
      final userPacks = await superlikeService.getUserPacks();
      final total = userPacks.fold<int>(0, (sum, pack) => sum + pack.remainingCount);
      
      if (mounted) {
        setState(() {
          _totalSuperlikes = total;
        });
      }
    } catch (e) {
      // Silently fail - user can still purchase packs
      if (mounted) {
        setState(() {
          _totalSuperlikes = 0;
        });
      }
    }
  }

  Future<void> _handlePurchase() async {
    if (_selectedPackId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pack'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    setState(() {
      _isPurchasing = true;
    });

    try {
      final superlikeService = ref.read(superlikePackServiceProvider);
      await superlikeService.purchasePack(
        PurchaseSuperlikePackRequest(packId: _selectedPackId!),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase successful!'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
        // Reload user superlikes
        _loadUserSuperlikes();
        // Refresh available packs
        ref.invalidate(availableSuperlikePacksProvider);
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
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  String _formatPrice(double price, String currency) {
    final symbol = currency.toUpperCase() == 'USD' ? '\$' : currency.toUpperCase();
    return '$symbol${price.toStringAsFixed(2)}';
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

    final availablePacksAsync = ref.watch(availableSuperlikePacksProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Superlike Packs',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Current superlikes
          Container(
            margin: EdgeInsets.all(AppSpacing.spacingLG),
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: AppSpacing.spacingMD),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Superlikes',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '$_totalSuperlikes',
                      style: AppTypography.h1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Packs list
          Expanded(
            child: availablePacksAsync.when(
              data: (packs) => packs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_outline,
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
                            'Superlike packs are not available at the moment.',
                            style: AppTypography.body.copyWith(color: secondaryTextColor),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(availableSuperlikePacksProvider);
                      },
                      child: ListView(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
                        children: [
                          SectionHeader(
                            title: 'Choose a Pack',
                            icon: Icons.shopping_bag,
                          ),
                          SizedBox(height: AppSpacing.spacingMD),
                          ...packs.map((pack) {
                            final isSelected = _selectedPackId == pack.id;
                            return Padding(
                              padding: EdgeInsets.only(bottom: AppSpacing.spacingMD),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPackId = pack.id;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(AppSpacing.spacingLG),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.accentPurple.withOpacity(0.1)
                                        : surfaceColor,
                                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accentPurple
                                          : (pack.isPopular ? AppColors.accentPink : borderColor),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    gradient: pack.isPopular
                                        ? LinearGradient(
                                            colors: [
                                              AppColors.accentPink.withOpacity(0.1),
                                              AppColors.accentPurple.withOpacity(0.1),
                                            ],
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Radio<int>(
                                        value: pack.id,
                                        groupValue: _selectedPackId,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedPackId = value;
                                          });
                                        },
                                        activeColor: AppColors.accentPurple,
                                      ),
                                      SizedBox(width: AppSpacing.spacingMD),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  pack.name,
                                                  style: AppTypography.h3.copyWith(
                                                    color: textColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (pack.isPopular) ...[
                                                  SizedBox(width: AppSpacing.spacingSM),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: AppSpacing.spacingSM,
                                                      vertical: AppSpacing.spacingXS,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      gradient: AppTheme.accentGradient,
                                                      borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                                                    ),
                                                    child: Text(
                                                      'BEST VALUE',
                                                      style: AppTypography.caption.copyWith(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (pack.description != null) ...[
                                              SizedBox(height: AppSpacing.spacingXS),
                                              Text(
                                                pack.description!,
                                                style: AppTypography.body.copyWith(
                                                  color: secondaryTextColor,
                                                ),
                                              ),
                                            ],
                                            SizedBox(height: AppSpacing.spacingXS),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _formatPrice(pack.price, pack.currency),
                                                  style: AppTypography.h1.copyWith(
                                                    color: textColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(width: AppSpacing.spacingXS),
                                                Padding(
                                                  padding: EdgeInsets.only(bottom: 4),
                                                  child: Text(
                                                    '/ ${pack.superlikeCount} superlikes',
                                                    style: AppTypography.body.copyWith(
                                                      color: secondaryTextColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          SizedBox(height: AppSpacing.spacingXXL),
                        ],
                      ),
                    ),
              loading: () => SkeletonLoading(),
              error: (error, stack) => ErrorDisplayWidget(
                errorMessage: error.toString(),
                onRetry: () {
                  ref.invalidate(availableSuperlikePacksProvider);
                },
              ),
            ),
          ),
          // Purchase button
          Padding(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: GradientButton(
              text: _isPurchasing ? 'Processing...' : 'Purchase',
              onPressed: _isPurchasing || _selectedPackId == null ? null : _handlePurchase,
              isLoading: _isPurchasing,
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}
