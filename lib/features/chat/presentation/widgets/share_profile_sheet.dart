import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../providers/chat_providers.dart';
import '../../data/models/chat.dart';

/// Bottom sheet to pick a match and share their profile in chat.
class ShareProfileSheet extends ConsumerStatefulWidget {
  final void Function(int profileUserId, String displayName) onProfileSelected;

  const ShareProfileSheet({
    super.key,
    required this.onProfileSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required void Function(int profileUserId, String displayName) onProfileSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareProfileSheet(onProfileSelected: onProfileSelected),
    );
  }

  @override
  ConsumerState<ShareProfileSheet> createState() => _ShareProfileSheetState();
}

class _ShareProfileSheetState extends ConsumerState<ShareProfileSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.radiusXL)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spacingLG),
              child: Text(
                'Share a profile',
                style: AppTypography.h4.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search matches...',
                  prefixIcon: AppSvgIcon(
                    assetPath: AppIcons.search,
                    size: 20,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  ),
                ),
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
              ),
            ),
            const SizedBox(height: AppSpacing.spacingMD),
            Expanded(
              child: FutureBuilder<List<Chat>>(
                future: ref.read(chatServiceProvider).getChatUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Could not load matches',
                        style: AppTypography.body.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    );
                  }

                  final chats = (snapshot.data ?? []).where((chat) {
                    if (_query.isEmpty) return true;
                    return chat.firstName.toLowerCase().contains(_query);
                  }).toList();

                  if (chats.isEmpty) {
                    return Center(
                      child: Text(
                        'No matches found',
                        style: AppTypography.body.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
                    itemCount: chats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.spacingSM),
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return Semantics(
                        label: 'Share profile of ${chat.firstName}',
                        button: true,
                        child: ListTile(
                          leading: AvatarWidget(
                            imageUrl: chat.primaryImageUrl,
                            radius: 22,
                            fallbackInitial: chat.firstName,
                          ),
                          title: Text(chat.firstName),
                          trailing: AppSvgIcon(
                            assetPath: AppIcons.share,
                            size: 20,
                            color: AppColors.primaryLight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onProfileSelected(chat.userId, chat.firstName);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
