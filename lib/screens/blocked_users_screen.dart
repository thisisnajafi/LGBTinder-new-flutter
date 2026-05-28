// Screen: BlockedUsersScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/avatar_widget.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_grouped_list_card.dart';
import '../core/widgets/app_settings_detail.dart';
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

    return AppSettingsDetailScaffold(
      title: 'Blocked users',
      action: IconButton(
        icon: AppSvgIcon(
          assetPath: AppIcons.getIconPath('refresh'),
          size: 22,
          color: theme.colorScheme.onSurface,
        ),
        onPressed: _loadBlockedUsers,
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
                          AppSvgIcon(
                            assetPath: AppIcons.block,
                            size: 64,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: AppSpacing.spacingMD),
                          Text(
                            'No blocked users',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.spacingSM),
                          Text(
                            'You haven\'t blocked anyone yet.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBlockedUsers,
                      child: AppSettingsDetailList(
                        children: [
                          AppGroupedListSection(
                            title: 'Blocked',
                            padding: AppSettingsLayout.firstSectionPadding,
                            children: [
                              for (var i = 0; i < _blockedUsers.length; i++)
                                _BlockedUserRow(
                                  blockedUser: _blockedUsers[i],
                                  formatDate: _formatDate,
                                  onUnblock: () =>
                                      _unblockUser(_blockedUsers[i]),
                                  showDivider: i < _blockedUsers.length - 1,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _BlockedUserRow extends StatelessWidget {
  final BlockedUser blockedUser;
  final String Function(DateTime) formatDate;
  final VoidCallback onUnblock;
  final bool showDivider;

  const _BlockedUserRow({
    required this.blockedUser,
    required this.formatDate,
    required this.onUnblock,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = blockedUser.lastName != null
        ? '${blockedUser.firstName} ${blockedUser.lastName}'
        : blockedUser.firstName;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingMD,
            vertical: AppSpacing.spacingMD,
          ),
          child: Row(
            children: [
              AvatarWidget(
                imageUrl: blockedUser.primaryImageUrl,
                radius: 28,
                fallbackInitial: fullName,
              ),
              const SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      'Blocked ${formatDate(blockedUser.blockedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    if (blockedUser.reason != null &&
                        blockedUser.reason!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.spacingXS,
                        ),
                        child: Text(
                          'Reason: ${blockedUser.reason}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onUnblock,
                child: const Text('Unblock'),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: AppSpacing.spacingMD,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
      ],
    );
  }
}
