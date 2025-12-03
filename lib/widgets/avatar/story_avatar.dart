// Widget: StoryAvatar
// Avatar for stories
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing_constants.dart';
import '../images/optimized_image.dart';
import 'avatar_with_ring.dart';

/// Story avatar widget
/// Avatar with gradient ring for stories (viewed/unviewed states)
class StoryAvatar extends ConsumerWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool isViewed;
  final bool hasNewStory;
  final VoidCallback? onTap;

  const StoryAvatar({
    Key? key,
    this.imageUrl,
    this.name,
    this.size = 64.0,
    this.isViewed = false,
    this.hasNewStory = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ringGradient = isViewed
        ? LinearGradient(
            colors: [
              isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
              isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
            ],
          )
        : AppTheme.accentGradient;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarWithRing(
            imageUrl: imageUrl,
            name: name,
            size: size,
            ringWidth: 3.0,
            ringGradient: ringGradient,
          ),
          if (name != null) ...[
            SizedBox(height: AppSpacing.spacingXS),
            SizedBox(
              width: size + 6,
              child: Text(
                name!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
