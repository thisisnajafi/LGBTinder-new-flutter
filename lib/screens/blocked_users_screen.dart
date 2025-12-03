// Screen: BlockedUsersScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/error_handling/error_display_widget.dart';
import '../widgets/loading/skeleton_loading.dart';
import '../features/safety/providers/user_actions_providers.dart';
import '../features/safety/data/models/block.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import 'package:intl/intl.dart';

/// Blocked users screen - Manage blocked users
class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  List<BlockedUser> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final userActionsService = ref.read(userActionsServiceProvider);
      final blockedUsers = await userActionsService.getBlockedUsers();

      if (mounted) {
        setState(() {
          _blockedUsers = blockedUsers;
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

  Future<void> _unblockUser(BlockedUser blockedUser) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock ${blockedUser.firstName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentPurple),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userActionsService = ref.read(userActionsServiceProvider);
      await userActionsService.unblockUser(blockedUser.blockedUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User unblocked successfully'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
        // Reload list
        _loadBlockedUsers();
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to unblock user',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to unblock user',
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
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
        title: 'Blocked Users',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            onPressed: _loadBlockedUsers,
          ),
        ],
      ),
      body: _isLoading
          ? SkeletonLoading()
          : _hasError && _blockedUsers.isEmpty
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage ?? 'Failed to load blocked users',
                  onRetry: _loadBlockedUsers,
                )
              : _blockedUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.block,
                            size: 64,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          SizedBox(height: AppSpacing.spacingMD),
                          Text(
                            'No Blocked Users',
                            style: AppTypography.h3.copyWith(color: textColor),
                          ),
                          SizedBox(height: AppSpacing.spacingSM),
                          Text(
                            'You haven\'t blocked any users yet.',
                            style: AppTypography.body.copyWith(
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBlockedUsers,
                      child: ListView.builder(
                        padding: EdgeInsets.all(AppSpacing.spacingMD),
                        itemCount: _blockedUsers.length,
                        itemBuilder: (context, index) {
                          final blockedUser = _blockedUsers[index];
                          final fullName = blockedUser.lastName != null
                              ? '${blockedUser.firstName} ${blockedUser.lastName}'
                              : blockedUser.firstName;

                          return Container(
                            margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
                            padding: EdgeInsets.all(AppSpacing.spacingMD),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: borderColor,
                                  backgroundImage: blockedUser.primaryImageUrl != null
                                      ? NetworkImage(blockedUser.primaryImageUrl!)
                                      : null,
                                  child: blockedUser.primaryImageUrl == null
                                      ? Icon(
                                          Icons.person,
                                          color: secondaryTextColor,
                                        )
                                      : null,
                                ),
                                SizedBox(width: AppSpacing.spacingMD),
                                // User info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fullName,
                                        style: AppTypography.body.copyWith(
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: AppSpacing.spacingXS),
                                      Text(
                                        'Blocked ${_formatDate(blockedUser.blockedAt)}',
                                        style: AppTypography.caption.copyWith(
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                      if (blockedUser.reason != null && blockedUser.reason!.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(top: AppSpacing.spacingXS),
                                          child: Text(
                                            'Reason: ${blockedUser.reason}',
                                            style: AppTypography.caption.copyWith(
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Unblock button
                                TextButton(
                                  onPressed: () => _unblockUser(blockedUser),
                                  child: Text(
                                    'Unblock',
                                    style: AppTypography.button.copyWith(
                                      color: AppColors.accentPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
