// Screen: WelcomeScreen
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/navbar/lgbtfinder_logo.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/app_logger.dart';

/// Welcome screen - First screen for authentication flow
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _buttonController;
  /// Single controller for all floating shapes to avoid 3 separate tickers (prevents animation freeze).
  late AnimationController _floatingController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _floatingAnimation;
  /// Defer floating shapes until after first frame to keep first paint light (avoids ANR).
  bool _showFloatingShapes = false;
  /// Minimal first frame: no ShaderMask/AnimatedBuilders so first paint is fast (avoids ANR).
  bool _minimalFirstFrame = true;
  /// Ensure we only schedule/apply full UI once (prevents build loop).
  bool _fullUIScheduled = false;
  /// Precache logo once so full UI frame doesn't block on decode.
  bool _precacheScheduled = false;
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    screenLog('WelcomeScreen', 'initState');
    startupLog('WelcomeScreen: reached WELCOME');

    // Create controllers only; do not start animations here to keep first frame light (avoids ANR).
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: AppAnimations.curveDefault),
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );

    // One shared controller for all floating shapes (1 ticker instead of 3 — avoids animation freeze).
    _floatingController = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    );
    _floatingAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // In debug: stay on minimal frame only (no full UI, no animations). Avoids freeze from heavy build + tickers.
    if (kDebugMode) {
      return;
    }
    // Release/profile: defer full UI across frames.
    // Frame 1: minimal. Frame 2: full without shapes + start logo. Floating shapes after ~2s.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _fullUIScheduled) return;
      _fullUIScheduled = true;
      setState(() {
        _minimalFirstFrame = false;
        _showFloatingShapes = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _logoController.forward().then((_) {
          if (!mounted) return;
          _textController.forward().then((_) {
            if (!mounted) return;
            _buttonController.forward();
          });
        });
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (!mounted) return;
          _floatingController.repeat(reverse: true);
          setState(() => _showFloatingShapes = true);
        });
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      _buildCount++;
      screenLog('WelcomeScreen', 'build #$_buildCount');
    }
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    final modernGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF6366F1),
        const Color(0xFF8B5CF6),
        const Color(0xFFEC4899),
        const Color(0xFFF97316),
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    );

    // Minimal first frame: no ShaderMask, no AnimatedBuilders, no shadows — fast paint to avoid ANR.
    if (_minimalFirstFrame) {
      if (!_precacheScheduled && context.mounted) {
        _precacheScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          precacheImage(const AssetImage(LGBTFinderLogo.assetPath), context);
        });
      }
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: modernGradient),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingXXL,
                vertical: AppSpacing.spacingXL,
              ),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.1),
                  // App logo with soft glow (no circle)
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.35),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: LGBTFinderLogo(size: 120),
                  ),
                  SizedBox(height: AppSpacing.spacingXXL),
                  Text(
                    'LGBTFinder',
                    style: AppTypography.h1Large.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.spacingLG),
                  Text(
                    'Find your perfect match',
                    style: AppTypography.h2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.spacingXL),
                  Text(
                    'Connect with like-minded people in a safe, inclusive community designed for everyone.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.go('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.accentPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                        ),
                      ),
                      child: Text(
                        'Create Account',
                        style: AppTypography.button.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingLG),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                        ),
                      ),
                      child: Text(
                        'Sign In',
                        style: AppTypography.button.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingXXL),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Full UI with animations (after first frame). In debug use lighter visuals to avoid freeze.
    final isDebug = kDebugMode;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: modernGradient),
          ),
          if (_showFloatingShapes && !isDebug)
            RepaintBoundary(
              child: Stack(
                children: [
                  Positioned(
                    top: size.height * 0.1,
                    left: size.width * 0.1,
                    child: _FloatingShape(
                      size: 80,
                      color: Colors.white.withOpacity(0.1),
                      animation: _floatingAnimation,
                      phaseOffset: 0,
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.3,
                    right: size.width * 0.15,
                    child: _FloatingShape(
                      size: 60,
                      color: Colors.white.withOpacity(0.08),
                      animation: _floatingAnimation,
                      phaseOffset: 2 * math.pi / 3,
                    ),
                  ),
                  Positioned(
                    bottom: size.height * 0.25,
                    left: size.width * 0.2,
                    child: _FloatingShape(
                      size: 40,
                      color: Colors.white.withOpacity(0.12),
                      animation: _floatingAnimation,
                      phaseOffset: 4 * math.pi / 3,
                    ),
                  ),
                ],
              ),
            ),
          RepaintBoundary(
            child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingXXL,
                vertical: AppSpacing.spacingXL,
              ),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.1),
                  // Logo with soft glow (no circle)
                  AnimatedBuilder(
                    animation: _logoAnimation,
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.spacingLG),
                      decoration: BoxDecoration(
                        boxShadow: isDebug
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 48,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                      ),
                      child: LGBTFinderLogo(size: 120),
                    ),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoAnimation.value,
                        child: Opacity(
                          opacity: _logoAnimation.value,
                          child: child,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: AppSpacing.spacingXXL),
                  AnimatedBuilder(
                    animation: _textAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _textAnimation.value)),
                          child: Column(
                            children: [
                              // In debug skip ShaderMask (expensive) to avoid freeze; use plain Text.
                              isDebug
                                  ? Text(
                                      'LGBTFinder',
                                      style: AppTypography.h1Large.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  : ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.white.withOpacity(0.9),
                                          Colors.white.withOpacity(0.8),
                                        ],
                                      ).createShader(bounds),
                                      child: Text(
                                        'LGBTFinder',
                                        style: AppTypography.h1Large.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.3),
                                              offset: const Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                              SizedBox(height: AppSpacing.spacingLG),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.spacingLG,
                                  vertical: AppSpacing.spacingMD,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Find your perfect match',
                                  style: AppTypography.h2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: AppSpacing.spacingXL),
                              Text(
                                'Connect with like-minded people in a safe, inclusive community designed for everyone.',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _buttonAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _buttonAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - _buttonAnimation.value)),
                          child: Column(
                            children: [
                              GradientButton(
                                text: 'Create Account',
                                onPressed: () => context.go('/register'),
                                usePrideGradient: true,
                              ),
                              SizedBox(height: AppSpacing.spacingLG),
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: () => context.go('/login'),
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign In',
                                    style: AppTypography.button.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: AppSpacing.spacingXXL),
                            ],
                          ),
                        ),
                      );
                    },
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

/// Floating animated shape — uses shared [animation] from parent (single ticker for all shapes).
class _FloatingShape extends StatelessWidget {
  final double size;
  final Color color;
  final Animation<double> animation;
  final double phaseOffset;

  const _FloatingShape({
    required this.size,
    required this.color,
    required this.animation,
    this.phaseOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value + phaseOffset;
        return Transform.translate(
          offset: Offset(
            math.sin(value) * 10,
            math.cos(value) * 10,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
