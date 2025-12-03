import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../models/subscription_plan.dart';
import '../../providers/payment_provider.dart';

/// Plan card widget
/// Displays subscription plan details with purchase option
class PlanCard extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final bool isPopular;
  final VoidCallback? onTap;
  final VoidCallback? onPurchase;

  const PlanCard({
    Key? key,
    required this.plan,
    this.isSelected = false,
    this.isPopular = false,
    this.onTap,
    this.onPurchase,
  }) : super(key: key);

  @override
  ConsumerState<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends ConsumerState<PlanCard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isSelected) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(PlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _animationController.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paymentState = ref.watch(paymentProvider);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: widget.isPopular
                  ? LinearGradient(
                      colors: [
                        AppColors.primaryLight.withOpacity(0.8),
                        AppColors.secondaryLight.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.isSelected
                  ? AppColors.primaryLight.withOpacity(0.1)
                  : theme.colorScheme.surface,
              border: Border.all(
                color: widget.isSelected
                    ? AppColors.primaryLight
                    : widget.isPopular
                        ? AppColors.primaryLight.withOpacity(0.5)
                        : theme.colorScheme.outline.withOpacity(0.3),
                width: widget.isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isPopular
                      ? AppColors.primaryLight.withOpacity(0.3 + (_glowAnimation.value * 0.2))
                      : Colors.black.withOpacity(0.1),
                  spreadRadius: widget.isPopular ? 2 + (_glowAnimation.value * 2) : 1,
                  blurRadius: widget.isPopular ? 8 + (_glowAnimation.value * 4) : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with name and popular badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.plan.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: widget.isPopular
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (widget.isPopular) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'POPULAR',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (widget.plan.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.plan.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: widget.isPopular
                                ? Colors.white.withOpacity(0.9)
                                : theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '\$${widget.plan.price.toStringAsFixed(widget.plan.price % 1 == 0 ? 0 : 2)}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.isPopular
                                  ? Colors.white
                                  : AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.plan.duration != null ? '/${widget.plan.duration}' : '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: widget.isPopular
                                  ? Colors.white.withOpacity(0.7)
                                  : theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),

                      // Features
                      if (widget.plan.features != null && widget.plan.features!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...widget.plan.features!.map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              AppSvgIcon(
                                assetPath: AppIcons.check,
                                size: 16,
                                color: widget.isPopular
                                    ? Colors.white
                                    : AppColors.feedbackSuccess,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: widget.isPopular
                                        ? Colors.white.withOpacity(0.9)
                                        : theme.colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],

                      const SizedBox(height: 20),

                      // Purchase button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: paymentState.isPurchasing
                              ? null
                              : widget.onPurchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isPopular
                                ? Colors.white
                                : AppColors.primaryLight,
                            foregroundColor: widget.isPopular
                                ? AppColors.primaryLight
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: widget.isPopular ? 0 : 2,
                          ),
                          child: paymentState.isPurchasing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.isSelected ? 'Selected' : 'Choose Plan',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
