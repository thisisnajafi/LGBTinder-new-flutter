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
import '../../../widgets/navbar/lgbtfinder_logo.dart';

/// Full-screen celebration after profile wizard completion.
class OnboardingCelebrationScreen extends ConsumerStatefulWidget {
  final String displayName;
  final String? avatarUrl;
  final List<String> topInterests;

  const OnboardingCelebrationScreen({
    super.key,
    required this.displayName,
    this.avatarUrl,
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

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 900));
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOutBack),
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

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
              numberOfParticles: 24,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.spacingXL),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    "You're in!",
                    style: textTheme.displayMedium?.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  Text(
                    'Your profile is ready to shine',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimaryDark.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.spacingXXL),
                  ScaleTransition(
                    scale: _cardScale,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppSpacing.spacingXL),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.backgroundDark.withValues(alpha: 0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.tintVioletLight,
                            backgroundImage: widget.avatarUrl != null &&
                                    widget.avatarUrl!.startsWith('http')
                                ? NetworkImage(widget.avatarUrl!)
                                : null,
                            child: widget.avatarUrl == null ||
                                    !widget.avatarUrl!.startsWith('http')
                                ? const LGBTFinderLogo(size: 56)
                                : null,
                          ),
                          SizedBox(height: AppSpacing.spacingMD),
                          Text(
                            widget.displayName,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.topInterests.isNotEmpty) ...[
                            SizedBox(height: AppSpacing.spacingMD),
                            Wrap(
                              spacing: AppSpacing.spacingSM,
                              runSpacing: AppSpacing.spacingSM,
                              alignment: WrapAlignment.center,
                              children: widget.topInterests.take(3).map((tag) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.spacingMD,
                                    vertical: AppSpacing.spacingXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.tintRoseLight,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.radiusRound),
                                  ),
                                  child: Text(
                                    tag,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.accentRose,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
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
                  SizedBox(height: AppSpacing.spacingLG),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
