import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../features/chat/providers/chat_providers.dart';
import '../../features/chat/providers/conversation_mute_cache_provider.dart';
import '../../features/profile/data/models/user_profile.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../features/safety/presentation/screens/report_user_screen.dart';
import '../../features/safety/presentation/widgets/block_user_dialog.dart';
import '../../routes/app_router.dart';
import '../../shared/models/api_error.dart';

/// Slide-down peer info panel shown below the chat header.
class ChatUserInfoPanel extends ConsumerStatefulWidget {
  final int userId;
  final String name;
  final String? avatarUrl;
  final VoidCallback onClose;
  final ValueChanged<bool>? onMuteChanged;

  const ChatUserInfoPanel({
    super.key,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.onClose,
    this.onMuteChanged,
  });

  @override
  ConsumerState<ChatUserInfoPanel> createState() => _ChatUserInfoPanelState();
}

class _ChatUserInfoPanelState extends ConsumerState<ChatUserInfoPanel> {
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isMuted = false;
  bool _isMuting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
      widget.onMuteChanged?.call(_isMuted);
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

  void _openProfile() {
    widget.onClose();
    final target = Uri(
      path: AppRoutes.profileDetail,
      queryParameters: {'userId': widget.userId.toString()},
    ).toString();
    context.push(target);
  }

  void _openReport() {
    widget.onClose();
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
        userName: widget.name,
        userAvatar: widget.avatarUrl,
        onBlockSuccess: () {
          widget.onClose();
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  List<String> _interestLabels(UserProfile profile) {
    final raw = profile.additionalData?['interests'];
    if (raw is! List) return const [];
    return raw
        .map((item) {
          if (item is Map) return item['title']?.toString() ?? '';
          return item.toString();
        })
        .where((label) => label.isNotEmpty)
        .take(8)
        .toList();
  }

  String? _locationLabel(UserProfile profile) {
    final distance = profile.additionalData?['distance'];
    final city = profile.city;
    if (distance != null) {
      final km = distance is num ? distance.toDouble() : double.tryParse('$distance');
      if (km != null) return '${km.toStringAsFixed(1)} km away';
    }
    if (city != null && city.isNotEmpty) return city;
    if (profile.country != null && profile.country!.isNotEmpty) {
      return profile.country;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Material(
      elevation: 4,
      color: surfaceColor,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: _isLoading
            ? Padding(
                padding: EdgeInsets.all(AppSpacing.spacingXL),
                child: const Center(child: CircularProgressIndicator()),
              )
            : _error != null
                ? Padding(
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    child: Column(
                      children: [
                        Text(
                          'Could not load profile',
                          style: AppTypography.body.copyWith(color: textColor),
                        ),
                        SizedBox(height: AppSpacing.spacingSM),
                        TextButton(onPressed: _loadData, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _buildContent(
                    context,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    borderColor: borderColor,
                  ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    final profile = _profile;
    final photos = profile?.images ?? const [];
    final interests = profile != null ? _interestLabels(profile) : const <String>[];
    final location = profile != null ? _locationLabel(profile) : null;
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.spacingLG,
        AppSpacing.spacingMD,
        AppSpacing.spacingLG,
        AppSpacing.spacingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.name,
                  style: AppTypography.h2.copyWith(color: textColor),
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: AppSvgIcon(
                  assetPath: AppIcons.close,
                  size: 22,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
          if (location != null) ...[
            SizedBox(height: AppSpacing.spacingXS),
            Row(
              children: [
                AppSvgIcon(
                  assetPath: AppIcons.location,
                  size: 16,
                  color: secondaryTextColor,
                ),
                SizedBox(width: AppSpacing.spacingXS),
                Text(
                  location,
                  style: AppTypography.caption.copyWith(color: secondaryTextColor),
                ),
              ],
            ),
          ],
          if (photos.isNotEmpty) ...[
            SizedBox(height: AppSpacing.spacingMD),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => SizedBox(width: AppSpacing.spacingSM),
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    child: CachedNetworkImage(
                      imageUrl: photo.url,
                      width: 72,
                      height: 96,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 72,
                        height: 96,
                        color: borderColor,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 72,
                        height: 96,
                        color: borderColor,
                        child: AppSvgIcon(
                          assetPath: AppIcons.gallery,
                          size: 24,
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (interests.isNotEmpty) ...[
            SizedBox(height: AppSpacing.spacingMD),
            Text(
              'Interests',
              style: AppTypography.labelMedium.copyWith(color: textColor),
            ),
            SizedBox(height: AppSpacing.spacingSM),
            Wrap(
              spacing: AppSpacing.spacingSM,
              runSpacing: AppSpacing.spacingSM,
              children: interests
                  .map(
                    (label) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacingMD,
                        vertical: AppSpacing.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                      ),
                      child: Text(
                        label,
                        style: AppTypography.caption.copyWith(
                          color: accentColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          SizedBox(height: AppSpacing.spacingLG),
          Wrap(
            spacing: AppSpacing.spacingSM,
            runSpacing: AppSpacing.spacingSM,
            children: [
              _ActionChip(
                label: 'Profile',
                iconPath: AppIcons.user,
                onTap: _openProfile,
                accentColor: accentColor,
              ),
              _ActionChip(
                label: _isMuted ? 'Unmute' : 'Mute',
                iconPath: _isMuted ? AppIcons.bellSlash : AppIcons.bell,
                onTap: _isMuting ? null : _toggleMute,
                isLoading: _isMuting,
                accentColor: accentColor,
              ),
              _ActionChip(
                label: 'Report',
                iconPath: AppIcons.report,
                onTap: _openReport,
                accentColor: accentColor,
              ),
              _ActionChip(
                label: 'Block',
                iconPath: AppIcons.block,
                onTap: _openBlock,
                isDestructive: true,
                accentColor: accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDestructive;
  final Color accentColor;

  const _ActionChip({
    required this.label,
    required this.iconPath,
    required this.accentColor,
    this.onTap,
    this.isLoading = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.feedbackError : accentColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radiusSM),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.radiusSM),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              AppSvgIcon(assetPath: iconPath, size: 16, color: color),
            SizedBox(width: AppSpacing.spacingXS),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
