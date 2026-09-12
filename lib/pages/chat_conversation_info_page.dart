import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';

import '../core/cache/cache_providers.dart';
import '../core/cache/image_cache_service.dart';
import '../core/theme/app_colors.dart';
import '../core/responsive/responsive.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/typography.dart';
import '../core/utils/app_icons.dart';
import '../core/utils/media_url.dart';
import '../core/services/app_logger.dart';
import '../features/chat/data/local/chat_info_cache.dart';
import '../features/chat/data/models/shared_media_item.dart';
import '../features/chat/data/services/chat_service.dart';
import '../features/chat/providers/chat_providers.dart';
import '../features/chat/providers/chat_list_preview_provider.dart';
import '../features/chat/providers/conversation_mute_cache_provider.dart';
import '../features/chat/providers/conversation_pin_cache_provider.dart';
import '../features/chat/providers/pinned_count_provider.dart';
import '../features/chat/utils/chat_visual_media.dart';
import '../widgets/chat/chat_video_viewer.dart';
import '../features/profile/data/models/user_profile.dart';
import '../features/profile/providers/profile_providers.dart';
import '../features/profile/presentation/widgets/own_profile/profile_photo_utils.dart';
import '../features/safety/presentation/screens/report_user_screen.dart';
import '../features/safety/presentation/widgets/block_user_dialog.dart';
import '../routes/app_router.dart';
import '../shared/models/api_error.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../core/widgets/profile_image_widget.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/chat/last_seen_widget.dart';

/// Chat-only conversation details: identity, media, mute, safety.
class ChatConversationInfoPage extends ConsumerStatefulWidget {
  const ChatConversationInfoPage({
    super.key,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    this.isOnline = false,
  });

  final int userId;
  final String userName;
  final String? avatarUrl;
  final bool isOnline;

  @override
  ConsumerState<ChatConversationInfoPage> createState() =>
      _ChatConversationInfoPageState();
}

class _ChatConversationInfoPageState
    extends ConsumerState<ChatConversationInfoPage> {
  UserProfile? _profile;
  List<SharedMediaItem> _sharedMedia = const [];
  bool _isLoading = true;
  bool _isLoadingMedia = true;
  String? _error;
  bool _isMuted = false;
  bool _isMuting = false;
  bool _isPinned = false;
  bool _isPinning = false;

  @override
  void initState() {
    super.initState();
    final cached =
        ref.read(chatInfoCacheProvider.notifier).snapshotFor(widget.userId);
    if (cached.media.isNotEmpty) {
      _sharedMedia = cached.media;
      _isLoadingMedia = false;
    }
    if (widget.userName.trim().isNotEmpty) {
      _isLoading = false;
    }
    _isPinned = ref.read(conversationPinCacheProvider).contains(widget.userId);
    _loadData();
  }

  Future<void> _loadData() async {
    final cached = ref.read(chatInfoCacheProvider.notifier).snapshotFor(
          widget.userId,
        );
    final hadCachedMedia = cached.media.isNotEmpty || _sharedMedia.isNotEmpty;
    if (mounted && hadCachedMedia) {
      setState(() {
        if (cached.media.isNotEmpty) {
          _sharedMedia = cached.media;
        }
        _isLoadingMedia = false;
        _error = null;
      });
    }

    try {
      final chatService = ref.read(chatServiceProvider);
      final profileService = ref.read(profileServiceProvider);
      final results = await Future.wait([
        profileService.getUserProfile(widget.userId),
        chatService.isConversationMuted(widget.userId),
        chatService.isConversationPinned(widget.userId),
      ]);

      if (!mounted) return;
      setState(() {
        _profile = results[0] as UserProfile;
        _isMuted = results[1] as bool;
        _isPinned = results[2] as bool;
        _isLoading = false;
      });
      final avatar = primaryProfileImage(_profile?.images)?.avatarDisplayUrl ??
          primaryProfileImage(_profile?.images)?.imageUrl;
      if (avatar != null && avatar.isNotEmpty) {
        ref.read(chatListPreviewProvider.notifier).updatePeerAppearance(
              widget.userId,
              avatarUrl: avatar,
            );
      }
      unawaited(_loadSharedMedia(forceSpinner: !hadCachedMedia));
      unawaited(_refreshPinnedCount());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _sharedMedia.isEmpty ? e.toString() : null;
        _isLoading = false;
        if (_sharedMedia.isEmpty) _isLoadingMedia = false;
      });
    }
  }

  Future<void> _refreshPinnedCount() async {
    try {
      final count = await ref
          .read(chatServiceProvider)
          .getPinnedMessagesCount(widget.userId);
      await ref
          .read(chatInfoCacheProvider.notifier)
          .savePinnedCount(widget.userId, count);
      ref.invalidate(pinnedCountProvider(widget.userId));
    } catch (e) {
      AppLogger.warning(
        'Pinned count refresh failed',
        tag: 'Chat',
        error: e,
      );
    }
  }

  Future<void> _loadSharedMedia({bool forceSpinner = true}) async {
    if (forceSpinner && mounted && _sharedMedia.isEmpty) {
      setState(() => _isLoadingMedia = true);
    }

    try {
      final localRepo = ref.read(chatLocalRepositoryProvider);
      final chatService = ref.read(chatServiceProvider);
      final fromLocal = ChatVisualMedia.sharedFromMessages(
        await localRepo.getAllMessagesForOtherUser(widget.userId),
      );
      if (fromLocal.isNotEmpty && mounted) {
        setState(() {
          _sharedMedia = fromLocal;
          _isLoadingMedia = false;
        });
        unawaited(
          ChatVisualMedia.prefetchUrlsList(fromLocal.map((item) => item.url)),
        );
      }

      final collected = <SharedMediaItem>[];
      final seen = <String>{};
      ChatHistoryCursor? cursor;
      var hasMore = true;
      var pages = 0;

      while (hasMore && pages < 12 && mounted) {
        final result = await chatService.getChatHistory(
          receiverId: widget.userId,
          limit: 50,
          beforeId: cursor?.beforeId,
          beforeCreatedAt: cursor?.beforeCreatedAt,
        );
        await localRepo.upsertMessages(result.messages, widget.userId);
        unawaited(ChatVisualMedia.prefetchMessages(result.messages));

        for (final message in result.messages) {
          final item = ChatVisualMedia.sharedItem(message);
          if (item != null && seen.add(item.url)) {
            collected.add(item);
          }
        }

        hasMore = result.hasMore && result.nextCursor != null;
        cursor = result.nextCursor;
        pages++;
      }

      if (!mounted) return;
      setState(() {
        _sharedMedia = collected;
        _isLoadingMedia = false;
      });
      await ref.read(chatInfoCacheProvider.notifier).saveMedia(
            widget.userId,
            collected,
          );
    } catch (e) {
      AppLogger.warning(
        'Shared media load failed',
        tag: 'Chat',
        error: e,
      );
      if (!mounted) return;
      setState(() => _isLoadingMedia = false);
    }
  }

  String get _displayName {
    final profile = _profile;
    if (profile != null) {
      final first = profile.firstName.trim();
      if (first.isNotEmpty) return first;
    }
    return widget.userName;
  }

  String? get _displayAvatar {
    final primary = primaryProfileImage(_profile?.images);
    final url = primary?.avatarDisplayUrl ?? primary?.imageUrl;
    if (url != null && url.isNotEmpty) return url;
    return widget.avatarUrl;
  }

  bool get _isOnline => widget.isOnline || _profile?.isOnline == true;

  void _openProfile() {
    final target = Uri(
      path: AppRoutes.profileDetail,
      queryParameters: {'userId': widget.userId.toString()},
    ).toString();
    context.push(target);
  }

  void _openReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportUserScreen(userId: widget.userId),
      ),
    );
  }

  Future<void> _openBlock() async {
    await showDialog<void>(
      context: context,
      builder: (_) => BlockUserDialog(
        userId: widget.userId,
        userName: _displayName,
        userAvatar: _displayAvatar,
        onBlockSuccess: () {
          if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  Future<void> _toggleMute() async {
    setState(() => _isMuting = true);
    try {
      final chatService = ref.read(chatServiceProvider);
      final muted = _isMuted
          ? await chatService.unmuteConversation(widget.userId)
          : await chatService.muteConversation(widget.userId);

      if (!mounted) return;
      ref.read(conversationMuteCacheProvider.notifier).setMuted(widget.userId, muted);
      setState(() {
        _isMuted = muted;
        _isMuting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isMuted ? 'Conversation muted' : 'Conversation unmuted'),
        ),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _isMuting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMuting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update mute: $e')),
      );
    }
  }

  Future<void> _togglePin() async {
    setState(() => _isPinning = true);
    try {
      final chatService = ref.read(chatServiceProvider);
      final pinned = _isPinned
          ? await chatService.unpinConversation(widget.userId)
          : await chatService.pinConversation(widget.userId);

      if (!mounted) return;
      ref.read(conversationPinCacheProvider.notifier).setPinned(widget.userId, pinned);
      setState(() {
        _isPinned = pinned;
        _isPinning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPinned ? 'Conversation pinned' : 'Conversation unpinned'),
        ),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _isPinning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPinning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update pin: $e')),
      );
    }
  }

  void _openMediaViewer(int initialIndex) {
    if (initialIndex < 0 || initialIndex >= _sharedMedia.length) return;
    final tapped = _sharedMedia[initialIndex];
    if (tapped.isVideo) {
      unawaited(ChatVideoViewer.open(context, videoUrl: tapped.url));
      return;
    }

    final items = _sharedMedia.where((e) => !e.isVideo).toList();
    if (items.isEmpty) return;
    var index = initialIndex.clamp(0, items.length - 1);
    final imageOnlyIndex = items.indexWhere((e) => e.url == tapped.url);
    if (imageOnlyIndex >= 0) index = imageOnlyIndex;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoView(
            imageProvider: lgbtfinderCachedImageProvider(items[index].url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          ),
        ),
      ),
    );
  }

  EdgeInsets _listPadding(BuildContext context) {
    return EdgeInsets.fromLTRB(
      AppBreakpoints.value(
        context,
        phone: PremiumPageHeader.horizontalPadding,
        tablet: AppSpacing.spacingXL,
      ),
      AppSpacing.spacingMD,
      AppBreakpoints.value(
        context,
        phone: PremiumPageHeader.horizontalPadding,
        tablet: AppSpacing.spacingXL,
      ),
      AppSpacing.spacingXXL,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;
    final cachedInfo = ref.watch(
      chatInfoCacheProvider.select(
        (cache) => cache[widget.userId] ?? const ChatInfoCacheSnapshot(),
      ),
    );
    final pinnedCount = cachedInfo.pinnedCount > 0
        ? cachedInfo.pinnedCount
        : (ref.watch(pinnedCountProvider(widget.userId)).valueOrNull ?? 0);

    return PremiumDetailScaffold(
      title: 'Chat info',
      onBack: () => context.pop(),
      onRefresh: _isLoading || _error != null ? null : _loadData,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.spacingXL),
                    child: PremiumShell(
                      margin: EdgeInsets.zero,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Could not load info',
                            style: AppTypography.body.copyWith(color: textColor),
                          ),
                          const SizedBox(height: AppSpacing.spacingMD),
                          GradientButton(
                            text: 'Retry',
                            onPressed: _loadData,
                            isFullWidth: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView(
                    physics: AppScroll.bouncing,
                    padding: _listPadding(context),
                    children: [
                      PremiumShell(
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _InfoAvatar(
                              imageUrl: _displayAvatar,
                              userId: widget.userId,
                              isOnline: _isOnline,
                            ),
                            const SizedBox(height: AppSpacing.spacingMD),
                            AppText(
                              _displayName,
                              style: AppTypography.h2.copyWith(color: textColor),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                            const SizedBox(height: AppSpacing.spacingXS),
                            Center(
                              child: LastSeenWidget(
                                isOnline: _isOnline,
                                lastSeenAt: _profile?.lastSeen,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.spacingLG),
                            GradientButton(
                              text: 'View profile',
                              iconPath: AppIcons.user,
                              onPressed: _openProfile,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacingLG),
                      PremiumSettingsGroup(
                        title: 'Chat',
                        subtitle: 'This conversation',
                        margin: EdgeInsets.zero,
                        children: [
                          PremiumSettingsTile(
                            iconPath: AppIcons.bell,
                            title: 'Notifications on',
                            subtitle: 'Get alerts from this chat',
                            selected: !_isMuted,
                            onTap: _isMuting || !_isMuted ? () {} : _toggleMute,
                            trailing: _isMuting && _isMuted
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                          ),
                          PremiumSettingsTile(
                            iconPath: AppIcons.bellSlash,
                            title: 'Notifications muted',
                            subtitle: 'You will not get alerts from this chat',
                            selected: _isMuted,
                            onTap: _isMuting || _isMuted ? () {} : _toggleMute,
                            trailing: _isMuting && !_isMuted
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                          ),
                          PremiumSettingsTile(
                            iconPath: _isPinned
                                ? AppIcons.bookmark2
                                : AppIcons.bookmark,
                            title: _isPinned
                                ? 'Pinned to top'
                                : 'Pin conversation',
                            subtitle: _isPinned
                                ? 'This chat stays at the top of your list'
                                : 'Keep this chat at the top of your list',
                            selected: _isPinned,
                            onTap: _isPinning ? () {} : _togglePin,
                            trailing: _isPinning
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                          ),
                          PremiumSettingsTile(
                            iconPath: AppIcons.gallery,
                            title: 'Shared media',
                            subtitle: _isLoadingMedia
                                ? 'Loading…'
                                : _sharedMedia.isEmpty
                                    ? 'No photos or videos yet'
                                    : '${_sharedMedia.length} item${_sharedMedia.length == 1 ? '' : 's'}',
                            onTap: () {},
                            trailing: const SizedBox.shrink(),
                          ),
                          PremiumSettingsTile(
                            iconPath: AppIcons.getIconPath('bookmark'),
                            title: 'Pinned messages',
                            subtitle: pinnedCount == 0
                                ? 'None pinned'
                                : '$pinnedCount pinned',
                            onTap: () {},
                            trailing: const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.spacingLG),
                      PremiumShell(
                        margin: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PremiumSectionHeader(
                              title: 'Shared media',
                              subtitle: _isLoadingMedia
                                  ? 'From this chat'
                                  : '${_sharedMedia.length} in this chat',
                            ),
                            const SizedBox(height: AppSpacing.spacingMD),
                            if (_isLoadingMedia)
                              const Padding(
                                padding: EdgeInsets.all(AppSpacing.spacingXL),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (_sharedMedia.isEmpty)
                              AppText(
                                'Photos and videos you send here will show up in this chat.',
                                style: AppTypography.bodySmall
                                    .copyWith(color: secondaryTextColor),
                                maxLines: 3,
                                textAlign: TextAlign.start,
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _sharedMedia.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      ResponsiveGrid.photoColumns(context),
                                  mainAxisSpacing: AppSpacing.spacingSM,
                                  crossAxisSpacing: AppSpacing.spacingSM,
                                ),
                                itemBuilder: (context, index) {
                                  final item = _sharedMedia[index];
                                  return PremiumTapScale(
                                    onTap: () => _openMediaViewer(index),
                                    semanticLabel: 'Open shared media',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.radiusSM,
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl: item.url,
                                            cacheManager: ref.read(
                                              imageCacheServiceProvider,
                                            ),
                                            cacheKey: MediaUrl.cacheKey(
                                              url: item.url,
                                            ),
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              color: borderColor,
                                            ),
                                            errorWidget: (_, __, ___) =>
                                                Container(
                                              color: borderColor,
                                              child: AppSvgIcon(
                                                assetPath: AppIcons.gallery,
                                                size: 28,
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ),
                                          if (item.isVideo)
                                            Container(
                                              color: Colors.black
                                                  .withValues(alpha: 0.35),
                                              child: Center(
                                                child: AppSvgIcon(
                                                  assetPath: AppIcons.playCircle,
                                                  size: 32,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacingLG),
                      PremiumSettingsGroup(
                        title: 'Safety',
                        subtitle: 'This conversation',
                        margin: EdgeInsets.zero,
                        children: [
                          PremiumSettingsTile(
                            iconPath: AppIcons.report,
                            title: 'Report user',
                            onTap: _openReport,
                            accent: AppColors.feedbackWarning,
                          ),
                          PremiumSettingsTile(
                            iconPath: AppIcons.block,
                            title: 'Block user',
                            onTap: _openBlock,
                            destructive: true,
                          ),
                        ],
                      ),
                    ],
                  ),
    );
  }
}

class _InfoAvatar extends ConsumerWidget {
  const _InfoAvatar({
    required this.imageUrl,
    required this.userId,
    required this.isOnline,
  });

  final String? imageUrl;
  final int userId;
  final bool isOnline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isOnline)
            Container(
              width: 94,
              height: 94,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
              ),
            ),
          Container(
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
            ),
            child: ClipOval(
              child: ProfileImageWidget(
                imageUrl: imageUrl,
                userId: userId,
                width: 82,
                height: 82,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (isOnline)
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.onlineGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
