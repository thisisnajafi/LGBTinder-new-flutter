import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/typography.dart';
import '../core/utils/app_icons.dart';
import '../features/chat/data/models/message.dart';
import '../features/chat/data/services/chat_service.dart';
import '../features/chat/providers/chat_providers.dart';
import '../features/chat/providers/conversation_mute_cache_provider.dart';
import '../features/profile/data/models/user_profile.dart';
import '../features/profile/providers/profile_providers.dart';
import '../features/safety/presentation/screens/report_user_screen.dart';
import '../features/safety/presentation/widgets/block_user_dialog.dart';
import '../routes/app_router.dart';
import '../shared/models/api_error.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../core/widgets/profile_image_widget.dart';
import '../widgets/buttons/gradient_button.dart';

/// Full-screen chat peer details: profile summary, shared media, view profile.
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

class _SharedMediaItem {
  const _SharedMediaItem({
    required this.url,
    required this.isVideo,
    this.messageId,
  });

  final String url;
  final bool isVideo;
  final int? messageId;
}

class _ChatConversationInfoPageState
    extends ConsumerState<ChatConversationInfoPage> {
  UserProfile? _profile;
  List<_SharedMediaItem> _sharedMedia = const [];
  bool _isLoading = true;
  bool _isLoadingMedia = true;
  String? _error;
  bool _isMuted = false;
  bool _isMuting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isLoadingMedia = true;
      _error = null;
    });

    try {
      final chatService = ref.read(chatServiceProvider);
      final profileService = ref.read(profileServiceProvider);
      final results = await Future.wait([
        profileService.getUserProfile(widget.userId),
        chatService.isConversationMuted(widget.userId),
      ]);

      if (!mounted) return;
      setState(() {
        _profile = results[0] as UserProfile;
        _isMuted = results[1] as bool;
        _isLoading = false;
      });
      unawaited(_loadSharedMedia());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMedia = false;
      });
    }
  }

  Future<void> _loadSharedMedia() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final collected = <_SharedMediaItem>[];
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

        for (final message in result.messages) {
          final item = _mediaFromMessage(message);
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMedia = false);
    }
  }

  _SharedMediaItem? _mediaFromMessage(Message message) {
    if (message.isExpired) return null;
    final type = message.messageType.toLowerCase();
    final isImage = type.contains('image');
    final isVideo = type.contains('video');
    if (!isImage && !isVideo) return null;

    final url = message.attachmentUrl ??
        message.secureMediaUrl ??
        message.mediaThumbnailUrl;
    if (url == null || url.isEmpty) return null;

    return _SharedMediaItem(
      url: url,
      isVideo: isVideo,
      messageId: message.id > 0 ? message.id : null,
    );
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
    final images = _profile?.images;
    if (images != null && images.isNotEmpty) {
      return images.first.imageUrl;
    }
    return widget.avatarUrl;
  }

  List<String> _interestLabels(UserProfile profile) {
    if (profile.interestTitles != null && profile.interestTitles!.isNotEmpty) {
      return profile.interestTitles!.take(12).toList();
    }
    final raw = profile.additionalData?['interests'];
    if (raw is! List) return const [];
    return raw
        .map((item) {
          if (item is Map) return item['title']?.toString() ?? '';
          return item.toString();
        })
        .where((label) => label.isNotEmpty)
        .take(12)
        .toList();
  }

  String? _locationLabel(UserProfile profile) {
    final distance = profile.additionalData?['distance'];
    if (distance != null) {
      final km = distance is num ? distance.toDouble() : double.tryParse('$distance');
      if (km != null) return '${km.toStringAsFixed(1)} km away';
    }
    if (profile.city != null && profile.city!.isNotEmpty) {
      return profile.city;
    }
    if (profile.country != null && profile.country!.isNotEmpty) {
      return profile.country;
    }
    return null;
  }

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

  void _openMediaViewer(int initialIndex) {
    final items = _sharedMedia.where((e) => !e.isVideo).toList();
    if (items.isEmpty) return;
    var index = initialIndex.clamp(0, items.length - 1);
    final tapped = _sharedMedia[initialIndex];
    if (tapped.isVideo) return;
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
            imageProvider: NetworkImage(items[index].url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          ),
        ),
      ),
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

    return PremiumDetailScaffold(
      title: 'Chat info',
      onBack: () => context.pop(),
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
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      PremiumPageHeader.horizontalPadding,
                      AppSpacing.spacingMD,
                      PremiumPageHeader.horizontalPadding,
                      AppSpacing.spacingXXL,
                    ),
                    children: [
                      PremiumShell(
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _InfoAvatar(
                              imageUrl: _displayAvatar,
                              isOnline: widget.isOnline,
                            ),
                            const SizedBox(height: AppSpacing.spacingMD),
                            Text(
                              _displayName,
                              style: AppTypography.h2.copyWith(color: textColor),
                              textAlign: TextAlign.center,
                            ),
                            if (_profile != null &&
                                _locationLabel(_profile!) != null) ...[
                              const SizedBox(height: AppSpacing.spacingXS),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppSvgIcon(
                                    assetPath: AppIcons.location,
                                    size: 16,
                                    color: secondaryTextColor,
                                  ),
                                  const SizedBox(width: AppSpacing.spacingXS),
                                  Text(
                                    _locationLabel(_profile!)!,
                                    style: AppTypography.caption
                                        .copyWith(color: secondaryTextColor),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_profile != null) ...[
                        if (_profile!.profileBio != null &&
                            _profile!.profileBio!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.spacingLG),
                          PremiumShell(
                            margin: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PremiumSectionHeader(title: 'About'),
                                const SizedBox(height: AppSpacing.spacingSM),
                                Text(
                                  _profile!.profileBio!.trim(),
                                  style: AppTypography.body
                                      .copyWith(color: secondaryTextColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_interestLabels(_profile!).isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.spacingLG),
                          PremiumShell(
                            margin: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PremiumSectionHeader(title: 'Interests'),
                                const SizedBox(height: AppSpacing.spacingSM),
                                Wrap(
                                  spacing: AppSpacing.spacingSM,
                                  runSpacing: AppSpacing.spacingSM,
                                  children: _interestLabels(_profile!)
                                      .map(
                                        (label) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.spacingMD,
                                            vertical: AppSpacing.spacingXS,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentViolet
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.radiusRound,
                                            ),
                                            border: Border.all(
                                              color: AppColors.accentViolet
                                                  .withValues(alpha: 0.28),
                                            ),
                                          ),
                                          child: Text(
                                            label,
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.accentViolet,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: AppSpacing.spacingXL),
                      GradientButton(
                        text: 'View profile',
                        iconPath: AppIcons.user,
                        onPressed: _openProfile,
                      ),
                      const SizedBox(height: AppSpacing.spacingXL),
                      PremiumSectionHeader(title: 'Shared media'),
                      const SizedBox(height: AppSpacing.spacingMD),
                      if (_isLoadingMedia)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.spacingXL),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_sharedMedia.isEmpty)
                        PremiumShell(
                          margin: EdgeInsets.zero,
                          child: Text(
                            'No photos or videos shared yet',
                            style: AppTypography.bodySmall
                                .copyWith(color: secondaryTextColor),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _sharedMedia.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
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
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: borderColor,
                                      ),
                                      errorWidget: (_, __, ___) => Container(
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
                      const SizedBox(height: AppSpacing.spacingXL),
                      PremiumSettingsGroup(
                        title: 'Actions',
                        margin: EdgeInsets.zero,
                        children: [
                          PremiumSettingsTile(
                            iconPath:
                                _isMuted ? AppIcons.bellSlash : AppIcons.bell,
                            title: _isMuted
                                ? 'Unmute notifications'
                                : 'Mute notifications',
                            onTap: _isMuting ? () {} : _toggleMute,
                            trailing: _isMuting
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
                ),
    );
  }
}

class _InfoAvatar extends ConsumerWidget {
  const _InfoAvatar({
    required this.imageUrl,
    required this.isOnline,
  });

  final String? imageUrl;
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
