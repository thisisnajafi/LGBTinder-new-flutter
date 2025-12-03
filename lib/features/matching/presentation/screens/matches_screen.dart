// Screen: MatchesScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../widgets/navbar/app_bar_custom.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_loading.dart';
import '../../../../widgets/avatar/avatar_with_status.dart';
import '../../../../widgets/badges/verification_badge.dart';
import '../../../../widgets/badges/premium_badge.dart';
import '../../providers/likes_providers.dart';
import '../../data/models/match.dart' as app_models;
import '../../../../shared/models/api_error.dart';
import '../../../../shared/services/error_handler_service.dart';
import '../../../../pages/chat_page.dart';
import 'package:intl/intl.dart';

/// Matches screen - Display all user matches
class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  List<app_models.Match> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final likesService = ref.read(likesServiceProvider);
      final matches = await likesService.getMatches();

      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
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
    // Navigate to chat with match
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(userId: (match as app_models.Match).userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Matches',
        showBackButton: true,
      ),
      body: _isLoading
          ? SkeletonLoading()
          : _hasError && _matches.isEmpty
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage ?? 'Failed to load matches',
                  onRetry: _loadMatches,
                )
              : _matches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: secondaryTextColor,
                          ),
                          SizedBox(height: AppSpacing.spacingMD),
                          Text(
                            'No Matches Yet',
                            style: AppTypography.h3.copyWith(color: textColor),
                          ),
                          SizedBox(height: AppSpacing.spacingSM),
                          Text(
                            'Start swiping to find your perfect match!',
                            style: AppTypography.body.copyWith(
                              color: secondaryTextColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacing.spacingXXL),
                          ElevatedButton(
                            onPressed: () {
                              context.go('/home');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentPurple,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.spacingXXL,
                                vertical: AppSpacing.spacingMD,
                              ),
                            ),
                            child: const Text('Start Discovering'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMatches,
                      child: ListView.builder(
                        padding: EdgeInsets.all(AppSpacing.spacingMD),
                        itemCount: _matches.length,
                        itemBuilder: (context, index) {
                          final match = _matches[index];
                          final fullName = match.lastName != null
                              ? '${match.firstName} ${match.lastName}'
                              : match.firstName;

                          return Container(
                            margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                              border: Border.all(color: borderColor),
                            ),
                            child: InkWell(
                              onTap: () => _handleMatchTap(match),
                              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.spacingMD),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Stack(
                                      children: [
                                        AvatarWithStatus(
                                          imageUrl: match.primaryImageUrl,
                                          name: fullName,
                                          isOnline: false, // Match model doesn't have isOnline yet
                                          size: 64.0,
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: AppSpacing.spacingMD),
                                    // Match info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  fullName,
                                                  style: AppTypography.body.copyWith(
                                                    color: textColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // Premium badge can be added when Match model includes isPremium
                                            ],
                                          ),
                                          SizedBox(height: AppSpacing.spacingXS),
                                          if (match.lastMessage != null) ...[
                                            Text(
                                              match.lastMessage!,
                                              style: AppTypography.body.copyWith(
                                                color: secondaryTextColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: AppSpacing.spacingXS),
                                          ],
                                          Text(
                                            'Matched ${_formatDate(match.matchedAt)}',
                                            style: AppTypography.caption.copyWith(
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Chat icon
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      color: AppColors.accentPurple,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
