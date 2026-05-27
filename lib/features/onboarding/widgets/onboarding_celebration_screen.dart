import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../routes/app_router.dart';
import '../../../widgets/buttons/gradient_button.dart';
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
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _revealController;
  late Animation<double> _cardScale;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 900));
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      if (AppAnimations.animationsEnabled(context)) {
        _confettiController.play();
        _revealController.forward();
      } else {
        _revealController.value = 1;
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  void _startDiscovering() {
    context.go(AppRoutes.home);
  }

  void _editProfile() {
    Navigator.of(context).pop();
    context.push(AppRoutes.profileEdit);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.brandGradient),
            child: SizedBox.expand(),
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
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.spacingMD,
                                  vertical: AppSpacing.spacingXS,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.radiusRound,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.28),
                                  ),
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
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: AppSpacing.spacingLG),
                              Text(
                                "You're in!",
                                style: textTheme.displayMedium?.copyWith(
                                  color: AppColors.textPrimaryDark,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: AppSpacing.spacingSM),
                              Text(
                                'Your profile is ready to shine',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textPrimaryDark
                                      .withValues(alpha: 0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: AppSpacing.spacingSM),
                              Text(
                                'This is how others will see you on Discover',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textPrimaryDark
                                      .withValues(alpha: 0.75),
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
                Padding(
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
                        child: GradientButton(
                          text: 'Start Discovering',
                          onPressed: _startDiscovering,
                          usePrideGradient: true,
                          iconPath: AppIcons.discover,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      Semantics(
                        label: 'Edit profile before discovering',
                        button: true,
                        child: OutlinedButton.icon(
                          onPressed: _editProfile,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            foregroundColor: AppColors.textPrimaryDark,
                            side: BorderSide(
                              color: AppColors.textPrimaryDark
                                  .withValues(alpha: 0.55),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.radiusMD),
                            ),
                          ),
                          icon: AppSvgIcon(
                            assetPath: AppIcons.userEdit,
                            size: 20,
                            color: AppColors.textPrimaryDark,
                          ),
                          label: Text(
                            'Edit Profile',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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
