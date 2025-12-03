// Screen: Superlike Packs Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../widgets/navbar/app_bar_custom.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_loading.dart';
import '../../providers/google_play_billing_provider.dart';
import '../../../../core/providers/feature_flags_provider.dart';

/// Superlike Packs Screen - Purchase superlike packs using Google Play Billing
class SuperlikePacksScreen extends ConsumerStatefulWidget {
  const SuperlikePacksScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SuperlikePacksScreen> createState() => _SuperlikePacksScreenState();
}

class _SuperlikePacksScreenState extends ConsumerState<SuperlikePacksScreen> {
  bool _isLoading = false;
  String? _selectedProductId;

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
        title: 'Superlike Packs',
        showBackButton: true,
      ),
      body: _buildBody(textColor, secondaryTextColor, surfaceColor, borderColor),
    );
  }

  Widget _buildBody(Color textColor, Color secondaryTextColor, Color surfaceColor, Color borderColor) {
    final oneTimeProductsAsync = ref.watch(oneTimeProductsProvider);
    final billingAvailabilityAsync = ref.watch(billingAvailabilityProvider);
    final paymentSystem = ref.watch(activePaymentSystemProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh product data
        ref.invalidate(oneTimeProductsProvider);
      },
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Header
          Text(
            'Boost Your Matches',
            style: AppTypography.h2.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingSM),
          Text(
            'Get more attention with Superlikes. Purchase packs to send unlimited superlikes.',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
          ),

          // Payment System Indicator
          Container(
            margin: EdgeInsets.only(top: AppSpacing.spacingLG),
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.accentPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(
                color: AppColors.accentPink.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: AppColors.accentPink,
                  size: 20,
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
          ),

          SizedBox(height: AppSpacing.spacingXXL),

          // Billing Availability Check
          billingAvailabilityAsync.when(
            data: (isAvailable) {
              if (!isAvailable) {
                return Container(
                  padding: EdgeInsets.all(AppSpacing.spacingLG),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    border: Border.all(color: AppColors.accentRed),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.accentRed,
                        size: 48,
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      Text(
                        'Google Play Billing Not Available',
                        style: AppTypography.h3.copyWith(color: AppColors.accentRed),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.spacingSM),
                      Text(
                        'Superlike purchases are not available on this device.',
                        style: AppTypography.body.copyWith(color: secondaryTextColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => ErrorDisplayWidget(
              errorMessage: 'Failed to check billing availability',
              onRetry: () => ref.invalidate(billingAvailabilityProvider),
            ),
          ),

          // Products List
          oneTimeProductsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(AppSpacing.spacingXXL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: secondaryTextColor,
                      ),
                      SizedBox(height: AppSpacing.spacingLG),
                      Text(
                        'No Packs Available',
                        style: AppTypography.h3.copyWith(color: textColor),
                      ),
                      SizedBox(height: AppSpacing.spacingSM),
                      Text(
                        'Superlike packs are not available at the moment.',
                        style: AppTypography.body.copyWith(color: secondaryTextColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: products.map((product) => _buildProductCard(
                  product,
                  textColor,
                  secondaryTextColor,
                  surfaceColor,
                  borderColor,
                )).toList(),
              );
            },
            loading: () => SkeletonLoading(),
            error: (error, stack) => ErrorDisplayWidget(
              errorMessage: 'Failed to load superlike packs',
              onRetry: () => ref.invalidate(oneTimeProductsProvider),
            ),
          ),

          SizedBox(height: AppSpacing.spacingXXL),

          // Purchase Button
          if (_selectedProductId != null)
            GradientButton(
              text: 'Purchase Pack',
              onPressed: _isLoading ? null : _purchasePack,
              isFullWidth: true,
              isLoading: _isLoading,
            ),

          SizedBox(height: AppSpacing.spacingLG),

          // Terms
          Text(
            'Superlikes never expire. You can use them anytime.',
            style: AppTypography.caption.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    ProductDetails product,
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    final isSelected = _selectedProductId == product.id;
    final packInfo = _parsePackInfo(product.id);

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accentPink.withOpacity(0.1) : surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(
          color: isSelected ? AppColors.accentPink : borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedProductId = isSelected ? null : product.id;
          });
        },
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with selection indicator
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          packInfo['name'] ?? product.title,
                          style: AppTypography.h3.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSpacing.spacingXS),
                        Text(
                          packInfo['description'] ?? product.description,
                          style: AppTypography.body.copyWith(color: secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                  Radio<String>(
                    value: product.id,
                    groupValue: _selectedProductId,
                    onChanged: (value) {
                      setState(() {
                        _selectedProductId = value;
                      });
                    },
                    activeColor: AppColors.accentPink,
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.spacingLG),

              // Pack details
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: AppColors.accentPink,
                    size: 24,
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  Text(
                    '${packInfo['count'] ?? 'Multiple'} Superlikes',
                    style: AppTypography.body.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.spacingMD),

              // Price
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingMD,
                  vertical: AppSpacing.spacingSM,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accentPink, AppColors.accentPurple],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                ),
                child: Text(
                  product.price,
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              if (packInfo['savings'] != null) ...[
                SizedBox(height: AppSpacing.spacingSM),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingSM,
                    vertical: AppSpacing.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.onlineGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    border: Border.all(color: AppColors.onlineGreen),
                  ),
                  child: Text(
                    'Save ${packInfo['savings']}%',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.onlineGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchasePack() async {
    if (_selectedProductId == null) return;

    setState(() => _isLoading = true);

    try {
      final purchaseNotifier = ref.read(googlePlayPurchaseProvider.notifier);
      await purchaseNotifier.initiatePurchase(_selectedProductId!, false); // false for one-time

      // Listen to purchase state changes
      ref.listen(googlePlayPurchaseProvider, (previous, next) {
        if (next.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Superlike pack purchased successfully!'),
              backgroundColor: AppColors.onlineGreen,
            ),
          );
          // Reset selection and navigate back
          setState(() => _selectedProductId = null);
          Navigator.of(context).pop();
        } else if (next.errorMessage != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Purchase failed: ${next.errorMessage}'),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Parse pack information from product ID
  Map<String, dynamic> _parsePackInfo(String productId) {
    switch (productId) {
      case 'superlike_small':
        return {
          'name': 'Small Pack',
          'description': 'Perfect for casual users',
          'count': 10,
          'savings': null,
        };
      case 'superlike_medium':
        return {
          'name': 'Medium Pack',
          'description': 'Great value for regular users',
          'count': 25,
          'savings': 15,
        };
      case 'superlike_large':
        return {
          'name': 'Large Pack',
          'description': 'Best for power users',
          'count': 50,
          'savings': 25,
        };
      case 'superlike_mega':
        return {
          'name': 'Mega Pack',
          'description': 'Maximum superlikes for serious daters',
          'count': 100,
          'savings': 35,
        };
      default:
        return {
          'name': 'Superlike Pack',
          'description': 'Extra superlikes for your account',
          'count': null,
          'savings': null,
        };
    }
  }
}
