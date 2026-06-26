// Screen: MatchesScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/user_profile_providers.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_settings_detail.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../../../core/widgets/profile_image_widget.dart';
import '../../../../routes/app_router.dart';
import '../../../../widgets/error_handling/empty_state.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_loading.dart';
import '../../data/models/match.dart' as app_models;

/// Matches screen — cache-first list aligned with premium profile/settings UI.
class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMatches();
    });
  }

  Future<void> _refreshMatches() async {
    final session =
        await ref.read(tokenStorageServiceProvider).getUserSession();
    final userId = session?.user.id.toString();
    if (userId != null) {
      await ref.read(appCacheManagerProvider).revalidateMatchList(userId);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    return DateFormat('MMM d').format(date);
  }

  void _openChat(app_models.Match match) {
    final fullName = match.lastName != null
        ? '${match.firstName} ${match.lastName}'
        : match.firstName;

    final target = Uri(
      path: AppRoutes.chat,
      queryParameters: {
        'userId': match.userId.toString(),
        if (fullName.trim().isNotEmpty) 'userName': fullName.trim(),
        if (match.primaryImageUrl?.isNotEmpty == true)
          'avatarUrl': match.primaryImageUrl!,
      },
    ).toString();
    context.push(target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchesAsync = ref.watch(cachedMatchesProvider);

    return AppSettingsDetailScaffold(
      title: 'Matches',
      subtitle: 'People you\'ve matched with',
      action: IconButton(
        icon: AppSvgIcon(
          assetPath: AppIcons.getIconPath('refresh'),
          size: 22,
          color: theme.colorScheme.onSurface,
        ),
        onPressed: _refreshMatches,
      ),
      body: matchesAsync.when(
        loading: () => const SkeletonLoading(),
        error: (e, _) => ErrorDisplayWidget(
          errorMessage: e.toString(),
          onRetry: _refreshMatches,
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return EmptyState(
              title: 'No matches yet',
              message: 'Start swiping to find your perfect match.',
              iconPath: AppIcons.heart,
              actionLabel: 'Start discovering',
              onAction: () => context.go('${AppRoutes.home}/discovery'),
              secondaryActionLabel: 'Contact support',
              onSecondaryAction: () => context.push(AppRoutes.helpSupport),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(appCacheManagerProvider).revalidateAll();
              await _refreshMatches();
            },
            child: AppSettingsDetailList(
              children: [
                PremiumSettingsGroup(
                  title: 'Your matches',
                  subtitle:
                      '${matches.length} ${matches.length == 1 ? 'match' : 'matches'}',
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingLG,
                  ),
                  children: [
                    for (var i = 0; i < matches.length; i++)
                      _MatchRow(
                        match: matches[i],
                        formatDate: _formatDate,
                        onTap: () => _openChat(matches[i]),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.match,
    required this.formatDate,
    required this.onTap,
  });

  final app_models.Match match;
  final String Function(DateTime?) formatDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fullName = match.lastName != null
        ? '${match.firstName} ${match.lastName}'
        : match.firstName;
    final displayName = fullName.trim().isNotEmpty ? fullName.trim() : 'Match';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
      child: PremiumTapScale(
        onTap: onTap,
        semanticLabel: 'Chat with $displayName',
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacingMD),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadius.radiusLG),
            border: Border.all(
              color: AppColors.accentViolet.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              ClipOval(
                child: ProfileImageWidget(
                  imageUrl: match.primaryImageUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      'Matched ${formatDate(match.matchedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    if (match.lastMessage != null &&
                        match.lastMessage!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        match.lastMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              AppSvgIcon(
                assetPath: AppIcons.getIconPath('arrow-right-3'),
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
