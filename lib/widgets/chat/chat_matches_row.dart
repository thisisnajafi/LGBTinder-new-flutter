import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/spacing_constants.dart';
import '../../core/widgets/app_page_header.dart';
import '../../core/widgets/profile_image_widget.dart';
import '../../features/matching/data/models/match.dart';
import '../../routes/app_router.dart';

/// Horizontal scroll row of match avatar chips (REF-04).
class ChatMatchesRow extends StatelessWidget {
  final List<Match> matches;

  const ChatMatchesRow({
    super.key,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    if (matches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPageHeader.horizontalPadding,
          ),
          child: Text(
            'Likes and matches',
            style: theme.textTheme.bodySmall?.copyWith(
              color: mutedColor,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacingSM),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppPageHeader.horizontalPadding,
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
                onTap: () {
                  context.push(
                    Uri(
                      path: AppRoutes.chat,
                      queryParameters: {
                        'userId': match.userId.toString(),
                        if (match.firstName.isNotEmpty)
                          'userName': match.firstName,
                        if (match.primaryImageUrl?.isNotEmpty == true)
                          'avatarUrl': match.primaryImageUrl!,
                      },
                    ).toString(),
                  );
                },
              );
            },
          ),
        ),
      ],
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

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isNew
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: ProfileImageWidget(
                  imageUrl: match.primaryImageUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacingXS),
            Text(
              match.firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
