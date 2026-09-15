import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_action_bottom_sheet.dart';
import '../../../../core/widgets/app_list_view.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/debounced_search_field.dart';
import '../../providers/chat_list_preview_provider.dart';
import '../../providers/chat_providers.dart';

/// Bottom sheet to pick a match and share their profile in chat.
class ShareProfileSheet extends ConsumerStatefulWidget {
  final void Function(int profileUserId, String displayName) onProfileSelected;

  const ShareProfileSheet({
    super.key,
    required this.onProfileSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required void Function(int profileUserId, String displayName)
        onProfileSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheetShell(
        showCancel: true,
        body: ShareProfileSheet(onProfileSelected: onProfileSelected),
      ),
    );
  }

  @override
  ConsumerState<ShareProfileSheet> createState() => _ShareProfileSheetState();
}

class _ShareProfileSheetState extends ConsumerState<ShareProfileSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _loadingList = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_ensureChats());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ensureChats() async {
    final preview = ref.read(chatListPreviewProvider);
    if (preview.isSeeded && preview.items.isNotEmpty) return;
    setState(() => _loadingList = true);
    try {
      final chats =
          await ref.read(chatServiceProvider).getChatUsers(forceRefresh: true);
      if (!mounted) return;
      ref.read(chatListPreviewProvider.notifier).seedFromChats(chats);
    } catch (e) {
      AppLogger.warning(
        'Share profile sheet failed to load chats',
        tag: 'Chat',
        error: e,
      );
    }
    if (mounted) setState(() => _loadingList = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = ref.watch(chatListPreviewProvider).items;
    final visible = _query.isEmpty
        ? items
        : items
            .where((item) => item.name.toLowerCase().contains(_query))
            .toList();

    return AppBottomSheetListBody(
      title: 'Share a profile',
      maxHeightFactor: 0.55,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spacingMD,
          0,
          AppSpacing.spacingMD,
          AppSpacing.spacingMD,
        ),
        child: DebouncedSearchField(
          controller: _searchController,
          hintText: 'Search matches...',
          decoration: InputDecoration(
            prefixIcon: AppSvgIcon(
              assetPath: AppIcons.search,
              size: 20,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppBottomSheetStyle.cornerRadius,
              ),
            ),
          ),
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
        ),
      ),
      child: _loadingList
          ? const Center(child: CircularProgressIndicator())
          : visible.isEmpty
              ? Center(
                  child: Text(
                    'No matches found',
                    style: AppTypography.body.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                )
              : AppListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.spacingSM),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                  ),
                  itemBuilder: (context, index) {
                    final item = visible[index];
                    return Semantics(
                      label: 'Share profile of ${item.name}',
                      button: true,
                      child: ListTile(
                        leading: AvatarWidget(
                          imageUrl: item.avatarUrl,
                          radius: 22,
                          fallbackInitial: item.name,
                        ),
                        title: AppText(
                          item.name,
                          maxLines: 1,
                        ),
                        trailing: AppSvgIcon(
                          assetPath: AppIcons.share,
                          size: 20,
                          color: AppColors.primaryLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppBottomSheetStyle.cornerRadius,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onProfileSelected(item.id, item.name);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
