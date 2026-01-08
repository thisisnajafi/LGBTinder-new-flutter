import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/badge_model.dart';
import '../../providers/marketing_providers.dart';

/// Badge display widget for showing badges on profiles
/// Part of the Marketing System Implementation (Task 3.4.4)
class BadgeDisplay extends ConsumerWidget {
  final BadgeModel badge;
  final double size;
  final bool showLabel;
  final bool showProgress;
  final VoidCallback? onTap;

  const BadgeDisplay({
    Key? key,
    required this.badge,
    this.size = 48,
    this.showLabel = false,
    this.showProgress = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isEarned = badge.isEarned;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge icon
          _buildBadgeIcon(theme, isEarned),

          // Label
          if (showLabel) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: size + 16,
              child: Text(
                badge.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isEarned
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: isEarned ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // Progress bar
          if (showProgress && !isEarned && badge.progressPercentage != null) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: size,
              child: LinearProgressIndicator(
                value: badge.progressPercentage! / 100,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getBadgeColor(badge.rarity),
                ),
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeIcon(ThemeData theme, bool isEarned) {
    final badgeColor = _getBadgeColor(badge.rarity);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isEarned
            ? LinearGradient(
                colors: [
                  badgeColor,
                  badgeColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isEarned ? null : theme.colorScheme.outline.withOpacity(0.2),
        boxShadow: isEarned
            ? [
                BoxShadow(
                  color: badgeColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        border: Border.all(
          color: isEarned ? badgeColor : theme.colorScheme.outline.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: badge.iconUrl != null && isEarned
            ? CachedNetworkImage(
                imageUrl: badge.iconUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholderIcon(theme, isEarned),
                errorWidget: (context, url, error) =>
                    _buildPlaceholderIcon(theme, isEarned),
              )
            : _buildPlaceholderIcon(theme, isEarned),
      ),
    );
  }

  Widget _buildPlaceholderIcon(ThemeData theme, bool isEarned) {
    return Icon(
      _getBadgeIconData(badge.category),
      size: size * 0.5,
      color: isEarned ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.3),
    );
  }

  Color _getBadgeColor(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'legendary':
        return const Color(0xFFFFD700); // Gold
      case 'epic':
        return AppColors.accentPurple;
      case 'rare':
        return const Color(0xFF2196F3); // Blue
      case 'uncommon':
        return AppColors.onlineGreen;
      default:
        return const Color(0xFF9E9E9E); // Grey for common
    }
  }

  IconData _getBadgeIconData(String? category) {
    switch (category?.toLowerCase()) {
      case 'social':
        return Icons.people;
      case 'engagement':
        return Icons.favorite;
      case 'premium':
        return Icons.diamond;
      case 'milestone':
        return Icons.emoji_events;
      case 'seasonal':
        return Icons.celebration;
      case 'special':
        return Icons.star;
      default:
        return Icons.military_tech;
    }
  }
}

/// Badge row for displaying multiple badges horizontally
class BadgeRow extends ConsumerWidget {
  final List<BadgeModel> badges;
  final int maxDisplay;
  final double badgeSize;
  final VoidCallback? onViewAll;

  const BadgeRow({
    Key? key,
    required this.badges,
    this.maxDisplay = 5,
    this.badgeSize = 32,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final displayBadges = badges.take(maxDisplay).toList();
    final remainingCount = badges.length - maxDisplay;

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Display badges
        ...displayBadges.map((badge) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: BadgeDisplay(
                badge: badge,
                size: badgeSize,
              ),
            )),

        // "+X more" indicator
        if (remainingCount > 0)
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  '+$remainingCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Badge grid for displaying all badges
class BadgeGrid extends ConsumerWidget {
  final List<BadgeModel> badges;
  final int crossAxisCount;
  final double spacing;
  final double badgeSize;
  final bool showLabels;
  final bool showProgress;
  final void Function(BadgeModel)? onBadgeTap;

  const BadgeGrid({
    Key? key,
    required this.badges,
    this.crossAxisCount = 4,
    this.spacing = 16,
    this.badgeSize = 64,
    this.showLabels = true,
    this.showProgress = true,
    this.onBadgeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: showLabels ? 0.8 : 1.0,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return BadgeDisplay(
          badge: badge,
          size: badgeSize,
          showLabel: showLabels,
          showProgress: showProgress,
          onTap: () => onBadgeTap?.call(badge),
        );
      },
    );
  }
}

/// Badge detail card for showing full badge information
class BadgeDetailCard extends StatelessWidget {
  final BadgeModel badge;
  final VoidCallback? onClaimReward;

  const BadgeDetailCard({
    Key? key,
    required this.badge,
    this.onClaimReward,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = _getBadgeColor(badge.rarity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.isEarned
              ? badgeColor.withOpacity(0.5)
              : theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge icon
          BadgeDisplay(
            badge: badge,
            size: 80,
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            badge.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          // Rarity
          if (badge.rarity != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge.rarity!.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Description
          if (badge.description != null)
            Text(
              badge.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

          // Progress or earned date
          if (badge.isEarned && badge.earnedAt != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.onlineGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  'Earned ${_formatDate(badge.earnedAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onlineGreen,
                  ),
                ),
              ],
            ),
          ] else if (badge.progressPercentage != null) ...[
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '${badge.progressPercentage!.toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: badge.progressPercentage! / 100,
                  backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ],

          // Reward section
          if (badge.isEarned &&
              badge.reward != null &&
              !badge.rewardClaimed) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onClaimReward,
                icon: const Icon(Icons.card_giftcard, size: 18),
                label: const Text('Claim Reward'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBadgeColor(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'legendary':
        return const Color(0xFFFFD700);
      case 'epic':
        return AppColors.accentPurple;
      case 'rare':
        return const Color(0xFF2196F3);
      case 'uncommon':
        return AppColors.onlineGreen;
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
