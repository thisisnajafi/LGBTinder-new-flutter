import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';

/// Profile stats row widget
/// Displays profile statistics like views, likes, matches
class ProfileStatsRow extends ConsumerWidget {
  final int? viewsCount;
  final int? likesCount;
  final int? matchesCount;
  final int? superLikesCount;

  const ProfileStatsRow({
    Key? key,
    this.viewsCount,
    this.likesCount,
    this.matchesCount,
    this.superLikesCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            context: context,
            icon: AppIcons.eye,
            label: 'Views',
            value: viewsCount ?? 0,
            color: AppColors.feedbackInfo,
          ),
          _buildDivider(context),
          _buildStatItem(
            context: context,
            icon: AppIcons.heart,
            label: 'Likes',
            value: likesCount ?? 0,
            color: AppColors.feedbackError,
          ),
          _buildDivider(context),
          _buildStatItem(
            context: context,
            icon: AppIcons.star,
            label: 'Matches',
            value: matchesCount ?? 0,
            color: AppColors.feedbackSuccess,
          ),
          if (superLikesCount != null && superLikesCount! > 0) ...[
            _buildDivider(context),
            _buildStatItem(
              context: context,
              icon: AppIcons.star,
              label: 'Super Likes',
              value: superLikesCount!,
              color: AppColors.primaryLight,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String icon,
    required String label,
    required int value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgIcon(
          assetPath: icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          _formatNumber(value),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 32,
      width: 1,
      color: theme.colorScheme.outline.withOpacity(0.2),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}
