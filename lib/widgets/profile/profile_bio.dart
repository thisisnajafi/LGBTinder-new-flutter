// Widget: ProfileBio — collapsible about section
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/utils/app_icons.dart';

class ProfileBio extends ConsumerStatefulWidget {
  final String? bio;
  final VoidCallback? onEdit;
  final bool isEditable;

  const ProfileBio({
    super.key,
    this.bio,
    this.onEdit,
    this.isEditable = false,
  });

  @override
  ConsumerState<ProfileBio> createState() => _ProfileBioState();
}

class _ProfileBioState extends ConsumerState<ProfileBio> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    if (widget.bio == null || widget.bio!.isEmpty) {
      if (!widget.isEditable) return const SizedBox.shrink();
      return Container(
        margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Add a bio to tell others about yourself',
                style: textTheme.bodyMedium?.copyWith(color: secondaryTextColor),
              ),
            ),
            if (widget.onEdit != null)
              Semantics(
                label: 'Add bio',
                button: true,
                child: IconButton(
                  icon: AppSvgIcon(
                    assetPath: AppIcons.add,
                    size: 22,
                    color: AppColors.accentPurple,
                  ),
                  onPressed: widget.onEdit,
                ),
              ),
          ],
        ),
      );
    }

    final bio = widget.bio!;
    final needsCollapse = bio.length > 120;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border(
          left: BorderSide(color: AppColors.accentRose, width: 3),
          top: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'About',
                style: textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.isEditable && widget.onEdit != null)
                Semantics(
                  label: 'Edit bio',
                  button: true,
                  child: IconButton(
                    icon: AppSvgIcon(
                      assetPath: AppIcons.edit,
                      size: 20,
                      color: AppColors.accentPurple,
                    ),
                    onPressed: widget.onEdit,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingMD),
          AnimatedCrossFade(
            duration: AppAnimations.transitionPage,
            crossFadeState:
                _expanded || !needsCollapse ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Text(
              bio,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(color: textColor, height: 1.5),
            ),
            secondChild: Text(
              bio,
              style: textTheme.bodyMedium?.copyWith(color: textColor, height: 1.5),
            ),
          ),
          if (needsCollapse)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Read less' : 'Read more',
                  style: textTheme.labelLarge?.copyWith(color: AppColors.accentPurple),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
