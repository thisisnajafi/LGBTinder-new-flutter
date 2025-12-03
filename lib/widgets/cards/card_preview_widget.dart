// Widget: CardPreviewWidget
// Card preview widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../images/optimized_image.dart';
import '../badges/verification_badge.dart';
import '../badges/premium_badge.dart';
import 'swipeable_card.dart';

/// Card preview widget
/// Compact preview of a swipeable card for lists/grids
class CardPreviewWidget extends ConsumerWidget {
  final int userId;
  final String name;
  final int? age;
  final String? avatarUrl;
  final bool isVerified;
  final bool isPremium;
  final VoidCallback? onTap;

  const CardPreviewWidget({
    Key? key,
    required this.userId,
    required this.name,
    this.age,
    this.avatarUrl,
    this.isVerified = false,
    this.isPremium = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(AppSpacing.spacingSM),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.radiusMD),
                topRight: Radius.circular(AppRadius.radiusMD),
              ),
              child: Stack(
                children: [
                  OptimizedImage(
                    imageUrl: avatarUrl ?? '',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  // Badges overlay
                  Positioned(
                    top: AppSpacing.spacingSM,
                    left: AppSpacing.spacingSM,
                    child: Row(
                      children: [
                        if (isVerified)
                          VerificationBadge(isVerified: true, size: 20),
                        if (isVerified && isPremium)
                          SizedBox(width: AppSpacing.spacingXS),
                        if (isPremium)
                          PremiumBadge(isPremium: true, fontSize: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.h3.copyWith(color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (age != null)
                        Text(
                          '$age',
                          style: AppTypography.body.copyWith(color: textColor),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
