import 'dart:math' as math;
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/app_icons.dart';
import '../../../routes/app_router.dart';
import 'onboarding_profile_preview_card.dart';

/// Full-screen celebration after profile wizard completion.
class OnboardingCelebrationScreen extends ConsumerStatefulWidget {
  final String displayName;
  final int? age;
  final String? location;
  final String? bio;
  final String? relationshipGoal;
  final int? heightCm;
  final List<String> photoSources;
  final List<String> topInterests;

  const OnboardingCelebrationScreen({
    super.key,
    required this.displayName,
    this.age,
    this.location,
    this.bio,
    this.relationshipGoal,
    this.heightCm,
    this.photoSources = const [],
    this.topInterests = const [],
  });

  @override
  ConsumerState<OnboardingCelebrationScreen> createState() =>
      _OnboardingCelebrationScreenState();
}

class _OnboardingCelebrationScreenState
    extends ConsumerState<OnboardingCelebrationScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _revealController;
  late AnimationController _ambientController;
  late Animation<double> _cardScale;
  late Animation<double> _headerFade;
  late Animation<Offset> _buttonsSlide;
  late Animation<double> _buttonsFade;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 900));
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _cardScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _buttonsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
      ),
    );
    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      if (AppAnimations.animationsEnabled(context)) {
        _confettiController.play();
        _revealController.forward();
        _ambientController.repeat();
      } else {
        _revealController.value = 1;
        _ambientController.value = 0;
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _revealController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _startDiscovering() {
    AppHaptics.light();
    Navigator.of(context).pop(true);
  }

  void _editProfile() {
    AppHaptics.selection();
    Navigator.of(context).pop();
    context.push(AppRoutes.profileEdit);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _ambientController,
            builder: (context, _) => _CelebrationBackground(
              drift: _ambientController.value,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: AppColors.lgbtGradient,
              numberOfParticles: 28,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.spacingXL,
                      AppSpacing.spacingLG,
                      AppSpacing.spacingXL,
                      AppSpacing.spacingMD,
                    ),
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _headerFade,
                          child: Column(
                            children: [
                              _CelebrationBadge(textTheme: textTheme),
                              SizedBox(height: AppSpacing.spacingLG),
                              Text(
                                "You're in!",
                                style: textTheme.displayMedium?.copyWith(
                                  color: AppColors.textPrimaryDark,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: AppSpacing.spacingSM),
                              Text(
                                'Your profile is ready to shine',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textPrimaryDark
                                      .withValues(alpha: 0.92),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: AppSpacing.spacingSM),
                              Text(
                                'This is how others will see you on Discover',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textPrimaryDark
                                      .withValues(alpha: 0.78),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSpacing.spacingXL),
                        ScaleTransition(
                          scale: _cardScale,
                          child: OnboardingProfilePreviewCard(
                            displayName: widget.displayName,
                            age: widget.age,
                            location: widget.location,
                            bio: widget.bio,
                            relationshipGoal: widget.relationshipGoal,
                            heightCm: widget.heightCm,
                            photoSources: widget.photoSources,
                            interests: widget.topInterests,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _buttonsFade,
                  child: SlideTransition(
                    position: _buttonsSlide,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.spacingXL,
                        AppSpacing.spacingSM,
                        AppSpacing.spacingXL,
                        AppSpacing.spacingLG,
                      ),
                      child: Column(
                        children: [
                          Semantics(
                            label: 'Start discovering matches',
                            button: true,
                            child: _CelebrationButton(
                              label: 'Start Discovering',
                              iconPath: AppIcons.discover,
                              primary: true,
                              onPressed: _startDiscovering,
                            ),
                          ),
                          SizedBox(height: AppSpacing.spacingMD),
                          Semantics(
                            label: 'Edit profile before discovering',
                            button: true,
                            child: _CelebrationButton(
                              label: 'Edit Profile',
                              iconPath: AppIcons.userEdit,
                              onPressed: _editProfile,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationBackground extends StatelessWidget {
  final double drift;

  const _CelebrationBackground({required this.drift});

  @override
  Widget build(BuildContext context) {
    final wave = math.sin(drift * math.pi * 2);
    final wave2 = math.cos(drift * math.pi * 2);

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF43F5E),
                Color(0xFFDB2777),
                Color(0xFF9333EA),
                Color(0xFF5B21B6),
              ],
              stops: [0.0, 0.32, 0.68, 1.0],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.prideGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -120 + wave * 18,
          right: -90 + wave2 * 14,
          child: _GlowOrb(
            size: 320,
            color: const Color(0xFFEC4899).withValues(alpha: 0.42),
          ),
        ),
        Positioned(
          top: 180 + wave2 * 22,
          left: -110 + wave * 16,
          child: _GlowOrb(
            size: 260,
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.38),
          ),
        ),
        Positioned(
          bottom: 120 + wave * 20,
          right: -70 + wave2 * 12,
          child: _GlowOrb(
            size: 220,
            color: const Color(0xFF457B9D).withValues(alpha: 0.28),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.35),
                radius: 1.1,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 260,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.32),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _CelebrationBadge extends StatelessWidget {
  final TextTheme textTheme;

  const _CelebrationBadge({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.42),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingMD,
              vertical: AppSpacing.spacingXS + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSvgIcon(
                  assetPath: AppIcons.checkCircle,
                  size: 16,
                  color: AppColors.textPrimaryDark,
                ),
                SizedBox(width: AppSpacing.spacingXS),
                Text(
                  'Profile complete',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationButton extends StatefulWidget {
  final String label;
  final String iconPath;
  final VoidCallback onPressed;
  final bool primary;

  const _CelebrationButton({
    required this.label,
    required this.iconPath,
    required this.onPressed,
    this.primary = false,
  });

  @override
  State<_CelebrationButton> createState() => _CelebrationButtonState();
}

class _CelebrationButtonState extends State<_CelebrationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: AppAnimations.tapDuration,
    );
    _scale = Tween<double>(begin: 1, end: AppAnimations.buttonPressScale)
        .animate(CurvedAnimation(
      parent: _pressController,
      curve: AppAnimations.curveDefault,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: Colors.white.withValues(alpha: 0.52),
      width: 1.5,
    );
    final radius = BorderRadius.circular(AppRadius.radiusRound);

    final content = SizedBox(
      width: double.infinity,
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSvgIcon(
            assetPath: widget.iconPath,
            size: 20,
            color: AppColors.textPrimaryDark,
          ),
          SizedBox(width: AppSpacing.spacingSM),
          Text(
            widget.label,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: (_) {
        if (AppAnimations.animationsEnabled(context)) {
          _pressController.forward();
        }
      },
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: radius,
          child: widget.primary
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: radius,
                    border: border,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentRose.withValues(alpha: 0.38),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: content,
                )
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: radius,
                      border: border,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: content,
                  ),
                ),
        ),
      ),
    );
  }
}
