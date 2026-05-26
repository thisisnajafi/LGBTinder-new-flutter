// Widget: ProfileActionButtons — sticky frosted action bar
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../buttons/icon_button_circle.dart';

class ProfileActionButtons extends ConsumerStatefulWidget {
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onSuperlike;
  final VoidCallback? onMessage;
  final bool isLiked;
  final bool isSuperliked;
  final bool isMatched;

  const ProfileActionButtons({
    super.key,
    this.onLike,
    this.onDislike,
    this.onSuperlike,
    this.onMessage,
    this.isLiked = false,
    this.isSuperliked = false,
    this.isMatched = false,
  });

  @override
  ConsumerState<ProfileActionButtons> createState() => _ProfileActionButtonsState();
}

class _ProfileActionButtonsState extends ConsumerState<ProfileActionButtons>
    with SingleTickerProviderStateMixin {
  late AnimationController _likePulse;

  @override
  void initState() {
    super.initState();
    _likePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _likePulse.dispose();
    super.dispose();
  }

  void _handleLike() {
    if (AppAnimations.animationsEnabled(context)) {
      _likePulse.forward(from: 0).then((_) => _likePulse.reverse());
    }
    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingLG,
            vertical: AppSpacing.spacingMD,
          ),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
                .withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (widget.onDislike != null)
                  Semantics(
                    label: 'Dislike profile',
                    button: true,
                    child: IconButtonCircle(
                      svgIcon: AppIcons.getIconPath('dislike'),
                      onTap: widget.onDislike,
                      size: 52,
                      iconColor: AppColors.textSecondaryLight,
                    ),
                  ),
                if (widget.onSuperlike != null)
                  Semantics(
                    label: 'Super like profile',
                    button: true,
                    child: IconButtonCircle(
                      svgIcon: AppIcons.getIconPath('star'),
                      onTap: widget.onSuperlike,
                      size: 52,
                      isActive: widget.isSuperliked,
                      iconColor: AppColors.warningYellow,
                    ),
                  ),
                if (widget.onLike != null)
                  Semantics(
                    label: widget.isMatched ? 'Matched' : 'Like profile',
                    button: true,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 1, end: 1.15).animate(
                        CurvedAnimation(parent: _likePulse, curve: Curves.elasticOut),
                      ),
                      child: IconButtonCircle(
                        svgIcon: AppIcons.heartOutline,
                        onTap: _handleLike,
                        size: 56,
                        backgroundColor: AppColors.notificationRed,
                        iconColor: AppColors.textPrimaryDark,
                        isActive: widget.isLiked || widget.isMatched,
                      ),
                    ),
                  ),
                if (widget.onMessage != null && widget.isMatched)
                  Semantics(
                    label: 'Send message',
                    button: true,
                    child: IconButtonCircle(
                      svgIcon: AppIcons.chatBubbleOutline,
                      onTap: widget.onMessage,
                      size: 52,
                      backgroundColor: AppColors.accentPurple,
                      iconColor: AppColors.textPrimaryDark,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating edit CTA for own profile.
class ProfileFloatingEditButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ProfileFloatingEditButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Edit profile',
      button: true,
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: AppColors.accentPurple,
        foregroundColor: AppColors.textPrimaryDark,
        icon: AppSvgIcon(
          assetPath: AppIcons.edit,
          size: 20,
          color: AppColors.textPrimaryDark,
        ),
        label: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
