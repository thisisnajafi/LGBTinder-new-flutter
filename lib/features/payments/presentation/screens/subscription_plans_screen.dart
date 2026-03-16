// Screen: SubscriptionPlansScreen
// Plan purchase UI aligned with backend PlanSeeder (Basic, Premium, Golden)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../widgets/navbar/app_bar_custom.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_loading.dart';
import '../../providers/payment_providers.dart';
import '../../providers/google_play_billing_provider.dart';
import '../../data/models/subscription_plan.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import '../widgets/offer_selection_widget.dart';
import '../utils/plan_theme_helper.dart';
import 'subscription_management_screen.dart';

/// Subscription plans screen — plan-themed UI (Basic, Premium, Golden)
class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends ConsumerState<SubscriptionPlansScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  List<SubscriptionPlan> _plans = [];
  List<SubPlan> _subPlans = [];
  int? _selectedPlanId;
  int? _selectedSubPlanId;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final plans = await paymentService.getPlans();
      final subPlans = await paymentService.getSubPlans();

      if (mounted) {
        setState(() {
          _plans = plans;
          _subPlans = subPlans;
          if (plans.isNotEmpty) {
            _selectedPlanId = plans.first.id;
            final firstSubPlan = subPlans.firstWhere(
              (sp) => sp.planId == plans.first.id,
              orElse: () => subPlans.first,
            );
            _selectedSubPlanId = firstSubPlan.id;
          }
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

  Future<void> _subscribe() async {
    if (_selectedPlanId == null || _selectedSubPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a plan'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    final paymentSystem = ref.read(activePaymentSystemProvider);

    if (paymentSystem == PaymentSystem.googlePlay) {
      await _subscribeWithGooglePlay();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No payment system available. Enable Google Play Billing in settings.'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _subscribeWithGooglePlay() async {
    try {
      final productId = _getGooglePlayProductId(_selectedPlanId!);

      if (productId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid plan selected'),
            backgroundColor: AppColors.accentRed,
          ),
        );
        return;
      }

      String? offerId;
      if (_selectedSubPlanId != null) {
        final selectedSubPlan = _subPlans.firstWhere(
          (sp) => sp.id == _selectedSubPlanId,
          orElse: () =>
              _subPlans.firstWhere((sp) => sp.planId == _selectedPlanId!),
        );
        offerId = selectedSubPlan.googleOfferId;
      }

      final purchaseNotifier = ref.read(googlePlayPurchaseProvider.notifier);
      await purchaseNotifier.initiatePurchase(productId, true, offerId: offerId);

      ref.listen(googlePlayPurchaseProvider, (previous, next) {
        if (next.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription successful!'),
              backgroundColor: AppColors.onlineGreen,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionManagementScreen(),
            ),
          );
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
    }
  }

  String? _getGooglePlayProductId(int planId) {
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Choose Plan',
        showBackButton: true,
      ),
      body: _isLoading
          ? SkeletonLoading()
          : _hasError && _plans.isEmpty
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage ?? 'Failed to load plans',
                  onRetry: _loadPlans,
                )
              : _plans.isEmpty
                  ? _buildEmptyState(secondaryTextColor, textColor)
                  : RefreshIndicator(
                      onRefresh: _loadPlans,
                      child: ListView(
                        padding: EdgeInsets.all(AppSpacing.spacingLG),
                        children: [
                          _buildHeader(textColor, secondaryTextColor),
                          _buildPaymentBadge(borderColor, textColor),
                          SizedBox(height: AppSpacing.spacingXL),
                          ..._plans.map((plan) => _buildPlanCard(
                                plan,
                                surfaceColor,
                                borderColor,
                                textColor,
                                secondaryTextColor,
                                isDark,
                              )),
                          SizedBox(height: AppSpacing.spacingXL),
                          GradientButton(
                            text: 'Subscribe Now',
                            onPressed: _subscribe,
                            isFullWidth: true,
                          ),
                          SizedBox(height: AppSpacing.spacingMD),
                          _buildViewSubscriptionLink(textColor),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildEmptyState(Color secondaryTextColor, Color textColor) {
    return Center(
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
            'No Plans Available',
            style: AppTypography.h3.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingSM),
          Text(
            'Subscription plans are not available at the moment.',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: AppTypography.h1.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpacing.spacingSM),
        Text(
          'Unlock premium features and enhance your experience.',
          style: AppTypography.body.copyWith(
            color: secondaryTextColor,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentBadge(Color borderColor, Color textColor) {
    return Consumer(
      builder: (context, ref, child) {
        final paymentSystem = ref.watch(activePaymentSystemProvider);
        return Container(
          margin: EdgeInsets.only(top: AppSpacing.spacingLG),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingMD,
            vertical: AppSpacing.spacingSM,
          ),
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            border: Border.all(
              color: AppColors.accentPurple.withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.payment_rounded,
                color: AppColors.accentPurple,
                size: 20,
              ),
              SizedBox(width: AppSpacing.spacingSM),
              Text(
                'Payment via ${paymentSystem.displayName}',
                style: AppTypography.body.copyWith(
                  color: AppColors.accentPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanCard(
    SubscriptionPlan plan,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final isSelected = _selectedPlanId == plan.id;
    final planSubPlans =
        _subPlans.where((sp) => sp.planId == plan.id).toList();
    final themeData = getPlanTheme(plan.name);
    final accent = themeData.accent;
    final cardBg = isSelected
        ? (isDark ? accent.withOpacity(0.12) : themeData.accentSoft)
        : surfaceColor;
    final border = isSelected ? accent : borderColor;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingLG),
      child: _PlanCard(
        plan: plan,
        planTheme: themeData,
        isSelected: isSelected,
        planSubPlans: planSubPlans,
        selectedSubPlanId: _selectedSubPlanId,
        cardBg: cardBg,
        border: border,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
        isDark: isDark,
        borderColor: borderColor,
        onPlanTap: () {
          setState(() {
            _selectedPlanId = plan.id;
            if (planSubPlans.isNotEmpty) {
              _selectedSubPlanId = planSubPlans.first.id;
            }
          });
        },
        onOfferSelected: (offer) {
          setState(() => _selectedSubPlanId = offer.id);
        },
      ),
    );
  }

  Widget _buildViewSubscriptionLink(Color textColor) {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionManagementScreen(),
            ),
          );
        },
        child: Text(
          'View current subscription',
          style: AppTypography.body.copyWith(
            color: AppColors.accentPurple,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Single plan card with theme, features, and offer selection
class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final PlanThemeData planTheme;
  final bool isSelected;
  final List<SubPlan> planSubPlans;
  final int? selectedSubPlanId;
  final Color cardBg;
  final Color border;
  final Color textColor;
  final Color secondaryTextColor;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onPlanTap;
  final void Function(SubPlan) onOfferSelected;

  const _PlanCard({
    required this.plan,
    required this.planTheme,
    required this.isSelected,
    required this.planSubPlans,
    required this.selectedSubPlanId,
    required this.cardBg,
    required this.border,
    required this.textColor,
    required this.secondaryTextColor,
    required this.isDark,
    required this.borderColor,
    required this.onPlanTap,
    required this.onOfferSelected,
  });

  @override
  Widget build(BuildContext context) {
    final features =
        plan.features?.isNotEmpty == true ? plan.features! : planTheme.features;
    final tagline =
        plan.description?.isNotEmpty == true ? plan.description! : planTheme.tagline;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(color: border, width: isSelected ? 2 : 1),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: planTheme.accent.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan header row with accent bar
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPlanTap,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.radiusLG),
              ),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left accent bar
                    Container(
                      width: 4,
                      height: 52,
                      margin: EdgeInsets.only(right: AppSpacing.spacingMD),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppRadius.radiusXS),
                        gradient: planTheme.gradient,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                plan.name,
                                style: AppTypography.h2.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (planTheme.isPopular) ...[
                                SizedBox(width: AppSpacing.spacingSM),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.spacingSM,
                                    vertical: AppSpacing.spacingXS,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: planTheme.gradient,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.radiusSM),
                                    boxShadow: [
                                      BoxShadow(
                                        color: planTheme.accent
                                            .withOpacity(0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Most popular',
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: AppSpacing.spacingXS),
                          Text(
                            tagline,
                            style: AppTypography.body.copyWith(
                              color: secondaryTextColor,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.spacingSM),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? planTheme.accent
                              : borderColor,
                          width: 2,
                        ),
                        color: isSelected
                            ? planTheme.accent.withOpacity(0.2)
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: planTheme.accent,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sub plans (billing cycle)
          if (planSubPlans.isNotEmpty && isSelected) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              child: OfferSelectionWidget(
                offers: planSubPlans,
                selectedOffer: planSubPlans.firstWhere(
                  (sp) => sp.id == selectedSubPlanId,
                  orElse: () => planSubPlans.first,
                ),
                onOfferSelected: onOfferSelected,
                recommendedOffer: planSubPlans.length > 1
                    ? planSubPlans.firstWhere(
                          (sp) =>
                              sp.duration
                                  ?.toLowerCase()
                                  .contains('12') ==
                                  true ||
                              sp.duration
                                  ?.toLowerCase()
                                  .contains('year') ==
                                  true ||
                              sp.duration
                                  ?.toLowerCase()
                                  .contains('annual') ==
                                  true ||
                              sp.name
                                  .toLowerCase()
                                  .contains('12') ==
                                  true,
                          orElse: () => planSubPlans.last,
                        )
                    : null,
              ),
            ),
          ],

          // Features
          if (features.isNotEmpty) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What\'s included',
                    style: AppTypography.body.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingSM),
                  ...features.map((feature) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.spacingXS),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: AppColors.onlineGreen,
                          ),
                          SizedBox(width: AppSpacing.spacingSM),
                          Expanded(
                            child: Text(
                              feature,
                              style: AppTypography.body.copyWith(
                                color: textColor,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
