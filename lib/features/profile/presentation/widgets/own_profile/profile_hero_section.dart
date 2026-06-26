import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/animation_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/border_radius_constants.dart';
import '../../../../../core/theme/spacing_constants.dart';
import '../../../../../core/utils/app_icons.dart';
import '../../../../../core/widgets/profile_image_widget.dart';
import '../../../../../core/widgets/profile_camera_badge.dart';
import '../../../../../features/matching/providers/likes_providers.dart';
import '../../../../../routes/home_tab_routes.dart';
import '../../../../../shared/models/user_tier.dart';
import '../../../widgets/tier_badge.dart';

/// Premium profile hero — identity, status, stats, and quick actions.
class ProfileHeroSection extends ConsumerStatefulWidget {
  const ProfileHeroSection({
    super.key,
    required this.fullName,
    required this.avatarUrl,
    required this.age,
    required this.isVerified,
    required this.tier,
    required this.locationLabel,
    required this.isOnline,
    required this.viewsCount,
    required this.superlikesRemaining,
    required this.onEditProfile,
    required this.onEditPhoto,
    required this.onViewProfile,
  });

  final String fullName;
  final String? avatarUrl;
  final int? age;
  final bool isVerified;
  final UserTier tier;
  final String? locationLabel;
  final bool isOnline;
  final int viewsCount;
  final int? superlikesRemaining;
  final VoidCallback onEditProfile;
  final VoidCallback onEditPhoto;
  final VoidCallback onViewProfile;

  @override
  ConsumerState<ProfileHeroSection> createState() =>
      _ProfileHeroSectionState();
}

class _ProfileHeroSectionState extends ConsumerState<ProfileHeroSection> {
  int _matchesCount = 0;
  int _likesReceived = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEngagementStats();
  }

  Future<void> _loadEngagementStats() async {
    try {
      final likesService = ref.read(likesServiceProvider);
      final results = await Future.wait([
        likesService.getMatches(),
        likesService.getPendingLikes(),
      ]);
      if (!mounted) return;
      setState(() {
        _matchesCount = results[0].length;
        _likesReceived = results[1].length;
        _statsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  void _openSettings() {
    context.go(HomeTabRoutes.locationForTab(4));
  }

  void _openSuperlikePacks() {
    context.pushNamed('superlike-packs');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenW = MediaQuery.sizeOf(context).width;
    final photoSize = (screenW * 0.28).clamp(104.0, 132.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spacingLG,
        AppSpacing.spacingXS,
        AppSpacing.spacingLG,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.radiusXL),
          child: Stack(
            children: [
              Positioned.fill(child: _CoverBackground(
                avatarUrl: widget.avatarUrl,
                isDark: isDark,
              )),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.25),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.spacingLG,
                  AppSpacing.spacingLG,
                  AppSpacing.spacingLG,
                  AppSpacing.spacingMD,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPhotoCard(context, photoSize, isDark),
                    const SizedBox(height: AppSpacing.spacingMD),
                    _buildIdentityRow(context, isDark),
                    const SizedBox(height: AppSpacing.spacingSM),
                    _buildMetaRow(context, isDark),
                    const SizedBox(height: AppSpacing.spacingSM),
                    Align(
                      alignment: Alignment.center,
                      child: TierBadge(tier: widget.tier, compact: false),
                    ),
                    const SizedBox(height: AppSpacing.spacingMD),
                    _buildQuickActions(context, isDark),
                    const SizedBox(height: AppSpacing.spacingMD),
                    _buildStatsPanel(context, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context, double size, bool isDark) {
    return Center(
      child: _HeroTapScale(
        onTap: widget.onViewProfile,
        onLongPress: widget.onEditPhoto,
        semanticLabel: 'View profile. Long press to change photo.',
        child: SizedBox(
          width: size + 12,
          height: size + 12,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: size + 8,
                height: size + 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentGradientStart,
                      AppColors.accentPink,
                      AppColors.feedbackInfo,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.radiusLG - 2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark.withValues(alpha: 0.55)
                          : Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(AppRadius.radiusLG - 2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.radiusLG - 2),
                      child: ProfileImageWidget(
                        imageUrl: widget.avatarUrl,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.isVerified)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.backgroundDark : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: AppSvgIcon(
                        assetPath: AppIcons.getIconPath('tick-circle', style: 'bold'),
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -2,
                bottom: -2,
                child: _HeroTapScale(
                  onTap: widget.onEditPhoto,
                  semanticLabel: 'Change profile photo',
                  child: const ProfileCameraBadge(size: 30, iconSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityRow(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final nameStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            widget.fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: nameStyle,
          ),
        ),
        if (widget.age != null) ...[
          Text(
            ', ${widget.age}',
            style: nameStyle?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
        if (widget.tier != UserTier.basid) ...[
          const SizedBox(width: 6),
          AppSvgIcon(
            assetPath: AppIcons.getIconPath('crown', style: 'bold'),
            size: 20,
            color: widget.tier == UserTier.golden
                ? AppColors.warningYellow
                : AppColors.accentViolet,
          ),
        ],
      ],
    );
  }

  Widget _buildMetaRow(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final muted = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Column(
      children: [
        if (widget.locationLabel != null && widget.locationLabel!.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(
                assetPath: AppIcons.getIconPath('location'),
                size: 15,
                color: AppColors.accentPink,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.locationLabel!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isOnline
                    ? AppColors.onlineGreen
                    : AppColors.textTertiaryDark,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.isOnline ? 'Online now' : 'Offline',
              style: theme.textTheme.labelMedium?.copyWith(
                color: widget.isOnline ? AppColors.onlineGreen : muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: AppIcons.userEdit,
            label: 'Edit',
            isPrimary: true,
            onTap: widget.onEditProfile,
          ),
        ),
        const SizedBox(width: AppSpacing.spacingSM),
        Expanded(
          child: _QuickActionButton(
            icon: AppIcons.getIconPath('star', style: 'bold'),
            label: 'Superlikes',
            onTap: _openSuperlikePacks,
          ),
        ),
        const SizedBox(width: AppSpacing.spacingSM),
        Expanded(
          child: _QuickActionButton(
            icon: AppIcons.setting2,
            label: 'Settings',
            onTap: _openSettings,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPanel(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.spacingMD,
        horizontal: AppSpacing.spacingSM,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardBackgroundDark.withValues(alpha: 0.85)
            : AppColors.cardBackgroundLight.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(
          color: AppColors.accentViolet.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
            children: [
              Expanded(
                child: _StatCell(
                  icon: AppIcons.eye,
                  label: 'Views',
                  value: widget.viewsCount,
                  color: AppColors.feedbackInfo,
                  loading: false,
                ),
              ),
              _statDivider(isDark),
              Expanded(
                child: _StatCell(
                  icon: AppIcons.heart,
                  label: 'Matches',
                  value: _matchesCount,
                  color: AppColors.accentPink,
                  loading: _statsLoading,
                ),
              ),
              _statDivider(isDark),
              Expanded(
                child: _StatCell(
                  icon: AppIcons.heartTick,
                  label: 'Likes',
                  value: _likesReceived,
                  color: AppColors.feedbackSuccess,
                  loading: _statsLoading,
                ),
              ),
              _statDivider(isDark),
              Expanded(
                child: _HeroTapScale(
                  onTap: () => context.pushNamed('superlike-packs'),
                  semanticLabel: 'Superlikes remaining. Tap to get more.',
                  child: _StatCell(
                    icon: AppIcons.getIconPath('star', style: 'bold'),
                    label: 'Superlikes',
                    value: widget.superlikesRemaining ?? 0,
                    color: AppColors.warningYellow,
                    loading: widget.superlikesRemaining == null,
                  ),
                ),
              ),
            ],
      ),
    );
  }

  Widget _statDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
    );
  }
}

class _CoverBackground extends StatelessWidget {
  const _CoverBackground({
    required this.avatarUrl,
    required this.isDark,
  });

  final String? avatarUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (avatarUrl != null && avatarUrl!.isNotEmpty)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Transform.scale(
              scale: 1.15,
              child: ProfileImageWidget(
                imageUrl: avatarUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E1064),
                  Color(0xFF4C1D95),
                  Color(0xFF831843),
                ],
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      AppColors.backgroundDark.withValues(alpha: 0.55),
                      AppColors.backgroundDark.withValues(alpha: 0.88),
                      AppColors.backgroundDark.withValues(alpha: 0.96),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.72),
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.96),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentViolet.withValues(alpha: isDark ? 0.22 : 0.12),
                AppColors.accentPink.withValues(alpha: isDark ? 0.14 : 0.08),
                AppColors.feedbackInfo.withValues(alpha: isDark ? 0.1 : 0.05),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return _HeroTapScale(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: isPrimary ? AppColors.brandGradient : null,
          color: isPrimary
              ? null
              : (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.65)),
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: isPrimary
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.35),
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(
              assetPath: icon,
              size: 16,
              color: isPrimary
                  ? Colors.white
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isPrimary
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.loading = false,
  });

  final String icon;
  final String label;
  final int value;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgIcon(assetPath: icon, size: 18, color: color),
        const SizedBox(height: 4),
        if (loading)
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color.withValues(alpha: 0.7),
            ),
          )
        else
          Text(
            _formatStat(value),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatStat(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _HeroTapScale extends StatefulWidget {
  const _HeroTapScale({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;

  @override
  State<_HeroTapScale> createState() => _HeroTapScaleState();
}

class _HeroTapScaleState extends State<_HeroTapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!AppAnimations.animationsEnabled(context)) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.96 : 1.0;

    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => _setPressed(true) : null,
        onTapUp: widget.onTap != null ? (_) => _setPressed(false) : null,
        onTapCancel: widget.onTap != null ? () => _setPressed(false) : null,
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
