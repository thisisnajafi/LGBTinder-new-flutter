// Screen: SubscriptionPlansScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../data/models/subscription_plan.dart' show SubscribeRequest;
import '../../../../shared/models/api_error.dart';
import '../../../../shared/services/error_handler_service.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import 'subscription_management_screen.dart';

/// Subscription plans screen - Display and select subscription plans
class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
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
            // Select first sub plan for selected plan
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
    } else if (paymentSystem == PaymentSystem.stripe) {
      await _subscribeWithStripe();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No payment system available'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _subscribeWithGooglePlay() async {
    try {
      // Map plan IDs to Google Play product IDs
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

      final purchaseNotifier = ref.read(googlePlayPurchaseProvider.notifier);
      await purchaseNotifier.initiatePurchase(productId, true); // true for subscription

      // The purchase notifier will handle success/error states
      // Listen to the state changes
      ref.listen(googlePlayPurchaseProvider, (previous, next) {
        if (next.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription successful!'),
              backgroundColor: AppColors.onlineGreen,
            ),
          );
          // Navigate to subscription management
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

  Future<void> _subscribeWithStripe() async {
    try {
      final paymentService = ref.read(paymentServiceProvider);
      final status = await paymentService.subscribeToPlan(
        SubscribeRequest(
          planId: _selectedPlanId!,
          subPlanId: _selectedSubPlanId!,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription successful!'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
        // Navigate to subscription management
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SubscriptionManagementScreen(),
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to subscribe',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to subscribe',
        );
      }
    }
  }

  /// Map plan IDs to Google Play product IDs
  String? _getGooglePlayProductId(int planId) {
    // Map your existing plan IDs to Google Play product IDs
    // This should be configurable based on your backend data
    switch (planId) {
      case 1: // Bronze plan
        return 'bronze_base';
      case 2: // Silver plan
        return 'silver_base';
      case 3: // Gold plan
        return 'gold_base';
      default:
        return null;
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Subscription Plans',
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
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPlans,
                      child: ListView(
                        padding: EdgeInsets.all(AppSpacing.spacingLG),
                        children: [
                          // Header
                          Text(
                            'Choose Your Plan',
                            style: AppTypography.h2.copyWith(color: textColor),
                          ),
                          SizedBox(height: AppSpacing.spacingSM),
                          Text(
                            'Unlock premium features and enhance your experience',
                            style: AppTypography.body.copyWith(color: secondaryTextColor),
                          ),

                          // Payment System Indicator
                          Consumer(
                            builder: (context, ref, child) {
                              final paymentSystem = ref.watch(activePaymentSystemProvider);
                              return Container(
                                margin: EdgeInsets.only(top: AppSpacing.spacingLG),
                                padding: EdgeInsets.all(AppSpacing.spacingMD),
                                decoration: BoxDecoration(
                                  color: AppColors.accentPurple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                                  border: Border.all(
                                    color: AppColors.accentPurple.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.payment,
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
                          ),

                          SizedBox(height: AppSpacing.spacingXXL),

                          // Plans list
                          ..._plans.map((plan) {
                            final isSelected = _selectedPlanId == plan.id;
                            final planSubPlans = _subPlans.where((sp) => sp.planId == plan.id).toList();

                            return Container(
                              margin: EdgeInsets.only(bottom: AppSpacing.spacingLG),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accentPurple.withOpacity(0.1)
                                    : surfaceColor,
                                borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.accentPurple
                                      : borderColor,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Plan header
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedPlanId = plan.id;
                                        if (planSubPlans.isNotEmpty) {
                                          _selectedSubPlanId = planSubPlans.first.id;
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(AppSpacing.spacingLG),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      plan.name,
                                                      style: AppTypography.h3.copyWith(
                                                        color: textColor,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (plan.isPopular) ...[
                                                      SizedBox(width: AppSpacing.spacingSM),
                                                      Container(
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: AppSpacing.spacingSM,
                                                          vertical: AppSpacing.spacingXS,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.accentPurple,
                                                          borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                                                        ),
                                                        child: Text(
                                                          'POPULAR',
                                                          style: AppTypography.caption.copyWith(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                if (plan.description != null) ...[
                                                  SizedBox(height: AppSpacing.spacingXS),
                                                  Text(
                                                    plan.description!,
                                                    style: AppTypography.body.copyWith(
                                                      color: secondaryTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Radio<int>(
                                            value: plan.id,
                                            groupValue: _selectedPlanId,
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedPlanId = value;
                                                if (planSubPlans.isNotEmpty) {
                                                  _selectedSubPlanId = planSubPlans.first.id;
                                                }
                                              });
                                            },
                                            activeColor: AppColors.accentPurple,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Sub plans (duration options)
                                  if (planSubPlans.isNotEmpty) ...[
                                    Divider(height: 1, color: borderColor),
                                    Padding(
                                      padding: EdgeInsets.all(AppSpacing.spacingMD),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Duration',
                                            style: AppTypography.body.copyWith(
                                              color: textColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: AppSpacing.spacingSM),
                                          Wrap(
                                            spacing: AppSpacing.spacingSM,
                                            runSpacing: AppSpacing.spacingSM,
                                            children: planSubPlans.map<Widget>((subPlan) {
                                              final isSubSelected = _selectedSubPlanId == subPlan.id;
                                              return InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedSubPlanId = subPlan.id;
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.spacingMD,
                                                    vertical: AppSpacing.spacingSM,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isSubSelected
                                                        ? AppColors.accentPurple
                                                        : surfaceColor,
                                                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                                                    border: Border.all(
                                                      color: isSubSelected
                                                          ? AppColors.accentPurple
                                                          : borderColor,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        _formatPrice(subPlan.price, subPlan.currency),
                                                        style: AppTypography.body.copyWith(
                                                          color: isSubSelected
                                                              ? Colors.white
                                                              : textColor,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (subPlan.duration != null)
                                                        Text(
                                                          subPlan.duration!,
                                                          style: AppTypography.caption.copyWith(
                                                            color: isSubSelected
                                                                ? Colors.white.withOpacity(0.9)
                                                                : secondaryTextColor,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Features
                                  if (plan.features != null && plan.features!.isNotEmpty) ...[
                                    Divider(height: 1, color: borderColor),
                                    Padding(
                                      padding: EdgeInsets.all(AppSpacing.spacingMD),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Features',
                                            style: AppTypography.body.copyWith(
                                              color: textColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: AppSpacing.spacingSM),
                                          ...plan.features!.map((feature) {
                                            return Padding(
                                              padding: EdgeInsets.only(bottom: AppSpacing.spacingXS),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    size: 20,
                                                    color: AppColors.onlineGreen,
                                                  ),
                                                  SizedBox(width: AppSpacing.spacingSM),
                                                  Expanded(
                                                    child: Text(
                                                      feature,
                                                      style: AppTypography.body.copyWith(
                                                        color: textColor,
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
                          }),

                          SizedBox(height: AppSpacing.spacingXXL),

                          // Subscribe button
                          GradientButton(
                            text: 'Subscribe Now',
                            onPressed: _subscribe,
                            isFullWidth: true,
                          ),

                          SizedBox(height: AppSpacing.spacingMD),

                          // View current subscription
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SubscriptionManagementScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'View Current Subscription',
                              style: AppTypography.button.copyWith(
                                color: AppColors.accentPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
