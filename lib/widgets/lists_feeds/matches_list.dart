// Widget: MatchesList
// Matches list widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../avatar/avatar_with_status.dart';
import '../badges/verification_badge.dart';
import '../badges/premium_badge.dart';
import '../error_handling/empty_state.dart';
import '../loading/skeleton_loader.dart';
import '../../core/utils/app_icons.dart';

/// Matches list widget
/// Displays a list of matched users
/// Data structure based on API: /api/matching/matches
class MatchesList extends ConsumerWidget {
  final List<Map<String, dynamic>> matches;
  final Function(int userId)? onMatchTap;
  final bool isLoading;
  final VoidCallback? onRetry;

  const MatchesList({
    Key? key,
    required this.matches,
    this.onMatchTap,
    this.isLoading = false,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    if (isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingLG,
              vertical: AppSpacing.spacingSM,
            ),
            child: SkeletonLoader(
              width: double.infinity,
              height: 80,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            ),
          );
        },
      );
    }

    if (matches.isEmpty) {
      return EmptyState(
        title: 'No matches yet',
        message: 'Keep swiping to find your match!',
        iconPath: AppIcons.favoriteBorder,
      );
    }

    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return _buildMatchItem(
          context: context,
          match: match,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
        );
      },
    );
  }

  Widget _buildMatchItem({
    required BuildContext context,
    required Map<String, dynamic> match,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingLG,
        vertical: AppSpacing.spacingSM,
      ),
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: () => onMatchTap?.call(match['id'] ?? 0),
        child: Row(
          children: [
            Stack(
              children: [
                AvatarWithStatus(
                  imageUrl: match['avatar_url'],
                  name: match['name'] ?? 'User',
                  isOnline: match['is_online'] ?? false,
                  size: 64.0,
                ),
                if (match['is_verified'] == true)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: VerificationBadge(isVerified: true, size: 20),
                  ),
              ],
            ),
            SizedBox(width: AppSpacing.spacingLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match['name'] ?? 'User',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: textColor,
                              ),
                        ),
                      ),
                      if (match['is_premium'] == true)
                        PremiumBadge(isPremium: true, fontSize: 10),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingXS),
                  if (match['last_message'] != null)
                    Text(
                      match['last_message'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: secondaryTextColor,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (match['matched_at'] != null)
                    Text(
                      'Matched ${_formatTime(match['matched_at'])}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: secondaryTextColor,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic time) {
    if (time == null) return '';
    // TODO: Parse time from API format - requires proper date parsing logic
    return 'recently'; // Placeholder
  }
}
