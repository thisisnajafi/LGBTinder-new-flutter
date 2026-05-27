// Screen: SubscriptionPlansScreen
// Plan purchase UI aligned with backend PlanSeeder (Basic, Premium, Golden)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_subscription_plans.dart';
import '../../providers/payment_providers.dart';
import '../../providers/google_play_billing_provider.dart';
import '../../data/models/subscription_plan.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import '../widgets/plan_duration_options.dart';
import '../utils/plan_theme_helper.dart';
import 'subscription_management_screen.dart';
import '../../../../shared/analytics/app_event_tracker.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appEventTrackerProvider).track('plans_view', meta: {'screen': 'subscription_plans'});
    });
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
        final embeddedSubPlans = plans
            .expand((plan) => plan.subPlans)
            .toList();
        final resolvedSubPlans = embeddedSubPlans.isNotEmpty
            ? embeddedSubPlans
            : subPlans;

        setState(() {
          _plans = plans;
          _subPlans = resolvedSubPlans;
          if (plans.isNotEmpty) {
            final defaultPlan = plans.firstWhere(
              (p) => p.name.toLowerCase().contains('premium'),
              orElse: () => plans.first,
            );
            _selectedPlanId = defaultPlan.id;
            final planOptions = _subPlansForPlan(defaultPlan.id);
            if (planOptions.isNotEmpty) {
              _selectedSubPlanId = planOptions.first.id;
            }
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
      ref.read(appEventTrackerProvider).track('plans_cta_subscribe', meta: {
        'plan_id': _selectedPlanId,
        'sub_plan_id': _selectedSubPlanId,
        'payment_system': 'google_play',
      });
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
      final selectedSubPlan = _selectedSubPlan;
      if (selectedSubPlan != null) {
        offerId = selectedSubPlan.googleOfferId;
      }

      final purchaseNotifier = ref.read(googlePlayPurchaseProvider.notifier);
      await purchaseNotifier.initiatePurchase(productId, true, offerId: offerId);

      ref.listen(googlePlayPurchaseProvider, (previous, next) {
        if (next.isSuccess && mounted) {
          ref.read(appEventTrackerProvider).track('purchase_success', meta: {
            'payment_system': 'google_play',
            'product_id': productId,
            'plan_id': _selectedPlanId,
            'sub_plan_id': _selectedSubPlanId,
          });
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
          ref.read(appEventTrackerProvider).track('purchase_failed', meta: {
            'payment_system': 'google_play',
            'product_id': productId,
            'plan_id': _selectedPlanId,
            'sub_plan_id': _selectedSubPlanId,
            'error': next.errorMessage,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Purchase failed: ${next.errorMessage}'),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      });
    } catch (e) {
      ref.read(appEventTrackerProvider).track('purchase_exception', meta: {
        'payment_system': 'google_play',
        'plan_id': _selectedPlanId,
        'sub_plan_id': _selectedSubPlanId,
        'error': e.toString(),
      });
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

  List<SubPlan> _subPlansForPlan(int planId) {
    final fromEmbedded =
        _plans.where((p) => p.id == planId).expand((p) => p.subPlans);
    final merged = <SubPlan>[...fromEmbedded];
    for (final sp in _subPlans.where((sp) => sp.planId == planId)) {
      if (!merged.any((m) => m.id == sp.id && sp.id != 0)) {
        merged.add(sp);
      }
    }
    merged.sort((a, b) => (a.durationDays ?? 0).compareTo(b.durationDays ?? 0));
    return merged;
  }

  SubPlan? get _selectedSubPlan {
    if (_selectedSubPlanId == null) return null;
    for (final sp in _subPlans) {
      if (sp.id == _selectedSubPlanId) return sp;
    }
    for (final plan in _plans) {
      for (final sp in plan.subPlans) {
        if (sp.id == _selectedSubPlanId) return sp;
      }
    }
    return null;
  }

  SubscriptionPlan? get _selectedPlan {
    if (_selectedPlanId == null) return null;
    for (final plan in _plans) {
      if (plan.id == _selectedPlanId) return plan;
    }
    return null;
  }

  String _formatPrice(double price, String currency) {
    final symbol =
        currency.toUpperCase() == 'USD' ? '\$' : currency.toUpperCase();
    final decimals = price % 1 == 0 ? 0 : 2;
    return '$symbol${price.toStringAsFixed(decimals)}';
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

    return AppPageScaffold(
      title: 'Choose Plan',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const SkeletonSubscriptionPlans()
          : _hasError && _plans.isEmpty
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage ?? 'Failed to load plans',
                  onRetry: _loadPlans,
                )
              : _plans.isEmpty
                  ? _buildEmptyState(secondaryTextColor, textColor)
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadPlans,
                            child: ListView(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.spacingLG,
                                AppSpacing.spacingLG,
                                AppSpacing.spacingLG,
                                AppSpacing.spacingSM,
                              ),
                              children: [
                                _buildHeader(textColor, secondaryTextColor),
                                _buildPaymentBadge(borderColor, textColor),
                                SizedBox(height: AppSpacing.spacingXL),
                                ..._plans.map(
                                  (plan) => _buildPlanCard(
                                    plan,
                                    surfaceColor,
                                    borderColor,
                                    textColor,
                                    secondaryTextColor,
                                    isDark,
                                  ),
                                ),
                                _buildViewSubscriptionLink(textColor),
                                SizedBox(height: AppSpacing.spacingMD),
                              ],
                            ),
                          ),
                        ),
                        _buildSubscribeBar(isDark, textColor),
                      ],
                    ),
    );
  }

  Widget _buildSubscribeBar(bool isDark, Color textColor) {
    final selectedPlan = _selectedPlan;
    final selectedSubPlan = _selectedSubPlan;
    final summary = selectedPlan != null && selectedSubPlan != null
        ? '${selectedPlan.name} · ${selectedSubPlan.durationLabel} · ${_formatPrice(selectedSubPlan.price, selectedSubPlan.currency)}'
        : 'Select a plan and billing period';

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
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.spacingSM),
            GradientButton(
              text: 'Subscribe Now',
              onPressed: _subscribe,
              isFullWidth: true,
            ),
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
    final planSubPlans = _subPlansForPlan(plan.id);
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
          setState(() {
            _selectedPlanId = plan.id;
            _selectedSubPlanId = offer.id;
          });
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
    final startingPerMonth = planSubPlans.isEmpty
        ? plan.price
        : planSubPlans
            .map((sp) => sp.perMonthPrice)
            .reduce((a, b) => a < b ? a : b);
    final startingCurrency =
        planSubPlans.isNotEmpty ? planSubPlans.first.currency : plan.currency;

    SubPlan? selectedOption;
    if (isSelected && selectedSubPlanId != null) {
      for (final sp in planSubPlans) {
        if (sp.id == selectedSubPlanId) {
          selectedOption = sp;
          break;
        }
      }
    }

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
                          if (planSubPlans.isNotEmpty) ...[
                            SizedBox(height: AppSpacing.spacingSM),
                            Text(
                              'From ${_formatCardPrice(startingPerMonth, startingCurrency)}/month',
                              style: AppTypography.labelMedium.copyWith(
                                color: planTheme.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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

          // Duration pricing — always visible for each tier
          if (planSubPlans.isNotEmpty) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              child: PlanDurationOptions(
                options: planSubPlans,
                selectedOption: selectedOption,
                accent: planTheme.accent,
                isDark: isDark,
                onOptionSelected: (offer) {
                  onOfferSelected(offer);
                  if (!isSelected) onPlanTap();
                },
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

  String _formatCardPrice(double price, String currency) {
    final symbol =
        currency.toUpperCase() == 'USD' ? '\$' : currency.toUpperCase();
    final decimals = price % 1 == 0 ? 0 : 2;
    return '$symbol${price.toStringAsFixed(decimals)}';
  }
}
