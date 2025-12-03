// Widget: ProfileActionButtons
// Profile action buttons row
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../buttons/gradient_button.dart';
import '../buttons/icon_button_circle.dart';
import '../../core/utils/app_icons.dart';

/// Profile action buttons widget
/// Displays action buttons for profile (like, superlike, message, etc.)
class ProfileActionButtons extends ConsumerWidget {
  final VoidCallback? onLike;
  final VoidCallback? onSuperlike;
  final VoidCallback? onMessage;
  final VoidCallback? onMore;
  final bool isLiked;
  final bool isSuperliked;
  final bool isMatched;

  const ProfileActionButtons({
    Key? key,
    this.onLike,
    this.onSuperlike,
    this.onMessage,
    this.onMore,
    this.isLiked = false,
    this.isSuperliked = false,
    this.isMatched = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingLG,
        vertical: AppSpacing.spacingMD,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (onSuperlike != null)
              IconButtonCircle(
                svgIcon: AppIcons.star,
                onTap: onSuperlike,
                size: 56.0,
                isActive: isSuperliked,
                iconColor: isSuperliked ? AppColors.warningYellow : null,
              ),
            if (onLike != null)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingSM),
                  child: GradientButton(
                    text: isMatched ? 'Matched!' : (isLiked ? 'Liked' : 'Like'),
                    onPressed: onLike,
                    iconPath: isLiked ? AppIcons.favorite : AppIcons.favoriteBorder,
                  ),
                ),
              ),
            if (onMessage != null && isMatched)
              IconButtonCircle(
                svgIcon: AppIcons.chatBubbleOutline,
                onTap: onMessage,
                size: 56.0,
                backgroundColor: AppColors.accentPurple,
                iconColor: Colors.white,
              ),
            if (onMore != null)
              IconButtonCircle(
                svgIcon: AppIcons.more,
                onTap: onMore,
                size: 56.0,
              ),
          ],
        ),
      ),
    );
  }
}
