// Screen: MatchesScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/cache/user_profile_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/widgets/cached_content_banner.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_loading.dart';
import '../../../../widgets/avatar/avatar_with_status.dart';
import '../../data/models/match.dart' as app_models;
import '../../../../pages/chat_page.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/error_handling/empty_state.dart';
import '../../../../routes/app_router.dart';
import '../../../../core/utils/app_icons.dart';

/// Matches screen - Display all user matches (cache-first).
class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

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
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  void _handleMatchTap(app_models.Match match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(userId: match.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark
        ? AppColors.borderMediumDark
        : AppColors.borderMediumLight;

    final matchesAsync = ref.watch(cachedMatchesProvider);

    return AppPageScaffold(
      title: 'Matches',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          const CachedContentBanner(),
          Expanded(
            child: matchesAsync.when(
              loading: () => SkeletonLoading(),
              error: (e, _) => ErrorDisplayWidget(
                errorMessage: e.toString(),
                onRetry: _refreshMatches,
              ),
              data: (matches) {
                if (matches.isEmpty) {
                  return EmptyState(
                    title: 'No Matches Yet',
                    message: 'Start swiping to find your perfect match.',
                    iconPath: AppIcons.heart,
                    actionLabel: 'Start discovering',
                    onAction: () =>
                        context.go('${AppRoutes.home}/discovery'),
                    secondaryActionLabel: 'Contact support',
                    onSecondaryAction: () =>
                        context.push(AppRoutes.helpSupport),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(appCacheManagerProvider).revalidateAll();
                    await _refreshMatches();
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(AppSpacing.spacingMD),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      final fullName = match.lastName != null
                          ? '${match.firstName} ${match.lastName}'
                          : match.firstName;

                      return Container(
                        margin:
                            EdgeInsets.only(bottom: AppSpacing.spacingMD),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          border: Border.all(color: borderColor),
                        ),
                        child: InkWell(
                          onTap: () => _handleMatchTap(match),
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.spacingMD),
                            child: Row(
                              children: [
                                AvatarWithStatus(
                                  imageUrl: match.primaryImageUrl,
                                  name: fullName,
                                  isOnline: false,
                                  size: 64.0,
                                ),
                                SizedBox(width: AppSpacing.spacingMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fullName,
                                        style: AppTypography.body.copyWith(
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(
                                          height: AppSpacing.spacingXS),
                                      Text(
                                        _formatDate(match.matchedAt),
                                        style: AppTypography.caption.copyWith(
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
