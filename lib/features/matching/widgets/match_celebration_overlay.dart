import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../profile/data/models/user_profile.dart';
import 'particle_burst_painter.dart';

/// Full-screen mutual-match celebration (~2.8s staged animation).
class MatchCelebrationOverlay extends StatefulWidget {
  static const Duration animationDuration = Duration(milliseconds: 2800);
  static const Duration autoDismissDuration = Duration(seconds: 8);

  final UserProfile currentUser;
  final UserProfile matchedUser;
  final String? currentUserAvatarUrl;
  final String? matchedUserAvatarUrl;
  final String matchId;
  final VoidCallback onSendMessage;
  final VoidCallback onKeepSwiping;

  const MatchCelebrationOverlay({
    super.key,
    required this.currentUser,
    required this.matchedUser,
    required this.matchId,
    required this.onSendMessage,
    required this.onKeepSwiping,
    this.currentUserAvatarUrl,
    this.matchedUserAvatarUrl,
  });

  @override
  State<MatchCelebrationOverlay> createState() => _MatchCelebrationOverlayState();
}

class _MatchCelebrationOverlayState extends State<MatchCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _autoDismissTimer;
  bool _userInteracted = false;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MatchCelebrationOverlay.animationDuration,
    );

    _autoDismissTimer = Timer(MatchCelebrationOverlay.autoDismissDuration, () {
      if (!_userInteracted && mounted) {
        widget.onKeepSwiping();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationStarted) return;
    _animationStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onUserAction(VoidCallback action) {
    _userInteracted = true;
    _autoDismissTimer?.cancel();
    action();
  }

  double _interval(double startMs, double endMs) {
    const total = 2800.0;
    return Interval(startMs / total, endMs / total, curve: AppAnimations.curveDefault)
        .transform(_controller.value);
  }

  List<Color> _particlePalette(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return [
      theme.colorScheme.primary,
      isDark ? AppColors.accentViolet : AppColors.accentPurple,
      AppColors.accentRose,
      AppColors.feedbackSuccess,
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final heartCenter = Offset(size.width / 2, size.height * 0.42);

    final bgOpacity = _interval(0, 400);
    final avatarProgress = _interval(200, 800);
    final heartProgress = _interval(600, 1000);
    final particleProgress = _interval(800, 1400);
    final textProgress = _interval(1000, 1600);
    final ctaProgress = _interval(1600, 2800);

    final heartScale = heartProgress < 0.55
        ? Curves.elasticOut.transform(heartProgress / 0.55) * 1.3
        : 1.0 + (1.0 - Curves.easeOut.transform((heartProgress - 0.55) / 0.45)) * 0.3;

    final particles = ParticleBurstPainter.computeBurst(
      center: heartCenter,
      t: particleProgress,
      palette: _particlePalette(context),
    );

    final slideOffset = (1.0 - Curves.elasticOut.transform(avatarProgress)) * 120;

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Phase 1 — background fade
          Opacity(
            opacity: bgOpacity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? AppColors.backgroundDark : AppColors.backgroundLight)
                        .withValues(alpha: 0.92),
                    theme.colorScheme.primary.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),

          // Phase 4 — particle burst
          CustomPaint(
            painter: ParticleBurstPainter(particles: particles),
            size: size,
          ),

          // Phase 2–3 — avatars + heart
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(-slideOffset, 0),
                      child: Opacity(
                        opacity: avatarProgress.clamp(0.0, 1.0),
                        child: _AvatarBubble(
                          imageUrl: widget.currentUserAvatarUrl,
                          label: widget.currentUser.firstName,
                          theme: theme,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.spacingLG),
                    Transform.scale(
                      scale: heartScale.clamp(0.0, 1.35),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.spacingMD),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.45),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: AppSvgIcon(
                          assetPath: AppIcons.heartOutline,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.spacingLG),
                    Transform.translate(
                      offset: Offset(slideOffset, 0),
                      child: Opacity(
                        opacity: avatarProgress.clamp(0.0, 1.0),
                        child: _AvatarBubble(
                          imageUrl: widget.matchedUserAvatarUrl,
                          label: widget.matchedUser.firstName,
                          theme: theme,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Phase 5 — headline + names
          Positioned(
            left: AppSpacing.contentPadding,
            right: AppSpacing.contentPadding,
            bottom: size.height * 0.22,
            child: Opacity(
              opacity: textProgress.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1.0 - textProgress) * 32),
                child: Column(
                  children: [
                    Semantics(
                      label: 'New Match',
                      header: true,
                      child: Text(
                        'New Match!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacingSM),
                    Text(
                      'Congratulations! You and ${widget.matchedUser.firstName} liked each other.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Phase 6 — CTAs
          Positioned(
            left: AppSpacing.contentPadding,
            right: AppSpacing.contentPadding,
            bottom: AppSpacing.spacingXXL + MediaQuery.paddingOf(context).bottom,
            child: Opacity(
              opacity: ctaProgress.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1.0 - ctaProgress) * 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      label: 'Start chat',
                      button: true,
                      child: ElevatedButton(
                        onPressed: () => _onUserAction(widget.onSendMessage),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.spacingMD,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.radiusMD),
                          ),
                        ),
                        child: Text(
                          'Start',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    Semantics(
                      label: 'Keep swiping',
                      button: true,
                      child: TextButton(
                        onPressed: () => _onUserAction(widget.onKeepSwiping),
                        child: Text(
                          'Keep Swiping',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBubble extends ConsumerWidget {
  const _AvatarBubble({
    required this.imageUrl,
    required this.label,
    required this.theme,
  });

  final String? imageUrl;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double diameter = 88;
    return Column(
      children: [
        Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: AvatarWidget(
            imageUrl: imageUrl,
            radius: diameter / 2 - 2,
            fallbackInitial: label,
          ),
        ),
      ],
    );
  }
}
