import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../core/widgets/profile_image_widget.dart';
import '../../features/matching/data/models/match.dart';
import '../../core/responsive/responsive.dart';

/// Horizontal scroll row of match avatar chips (REF-04).
class ChatMatchesRow extends StatelessWidget {
  final List<Match> matches;
  final ValueChanged<Match>? onMatchTap;

  const ChatMatchesRow({
    super.key,
    required this.matches,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PremiumPageHeader.horizontalPadding,
            ),
            child: PremiumSectionHeader(
              title: 'Likes and matches',
              subtitle: 'Tap to start chatting',
            ),
          ),
          const SizedBox(height: AppSpacing.spacingSM),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: PremiumPageHeader.horizontalPadding,
              ),
              itemCount: matches.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.spacingSM),
              itemBuilder: (context, index) {
                final match = matches[index];
                final isNew = match.isRead != true;
                return _MatchAvatarChip(
                  match: match,
                  isNew: isNew,
                  onTap: () => onMatchTap?.call(match),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchAvatarChip extends StatelessWidget {
  final Match match;
  final bool isNew;
  final VoidCallback onTap;

  const _MatchAvatarChip({
    required this.match,
    required this.isNew,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PremiumTapScale(
      onTap: onTap,
      semanticLabel: 'Chat with ${match.firstName}',
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isNew ? AppColors.brandGradient : null,
                color: isNew
                    ? null
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.5)),
                border: isNew
                    ? null
                    : Border.all(
                        color: AppColors.accentViolet.withValues(alpha: 0.2),
                      ),
              ),
              child: ClipOval(
                child: ProfileImageWidget(
                  imageUrl: match.primaryImageUrl,
                  userId: match.userId,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacingXS),
            AppText(
              match.firstName,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: isNew ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
