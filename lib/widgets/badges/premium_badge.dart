// Widget: PremiumBadge
// Premium user badge
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Premium user badge widget
/// Displays a premium badge with gradient background
class PremiumBadge extends ConsumerWidget {
  final bool isPremium;
  final double? fontSize;
  final EdgeInsets? padding;

  const PremiumBadge({
    Key? key,
    required this.isPremium,
    this.fontSize,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isPremium) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingSM,
        vertical: AppSpacing.spacingXS,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: (fontSize ?? 12) + 2,
            color: Colors.white,
          ),
          SizedBox(width: AppSpacing.spacingXS),
          Text(
            'Premium',
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
