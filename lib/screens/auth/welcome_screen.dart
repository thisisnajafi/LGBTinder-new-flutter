// Screen: WelcomeScreen
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../features/onboarding/widgets/welcome_glass_card.dart';
import '../../features/onboarding/widgets/welcome_profile_mosaic.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/navbar/lgbtfinder_logo.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/app_logger.dart';
import '../../routes/app_router.dart';

/// Welcome screen - First screen for authentication flow
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _buttonController;
  late AnimationController _floatingController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _floatingAnimation;

  bool _showFloatingShapes = false;
  bool _minimalFirstFrame = true;
  bool _fullUIScheduled = false;
  bool _precacheScheduled = false;
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    screenLog('WelcomeScreen', 'initState');
    startupLog('WelcomeScreen: reached WELCOME');

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
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutCubic),
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    );
    _floatingAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _fullUIScheduled) return;
      _fullUIScheduled = true;
      setState(() => _minimalFirstFrame = false);

      if (!AppAnimations.animationsEnabled(context)) {
        _logoController.value = 1;
        _textController.value = 1;
        _buttonController.value = 1;
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _logoController.forward().then((_) {
          if (!mounted) return;
          _textController.forward().then((_) {
            if (!mounted) return;
            _buttonController.forward();
          });
        });
        if (!kDebugMode) {
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (!mounted) return;
            _floatingController.repeat(reverse: true);
            setState(() => _showFloatingShapes = true);
          });
        }
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

  Widget _buildBrandingBlock(BuildContext context, {required bool animated}) {
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 1.5,
      color: AppColors.textPrimaryDark,
    );
    final taglineStyle = textTheme.displaySmall?.copyWith(
      color: AppColors.textPrimaryDark,
      fontWeight: FontWeight.w600,
    );
    final bodyStyle = textTheme.bodyLarge?.copyWith(
      color: AppColors.textPrimaryDark.withValues(alpha: 0.9),
      height: 1.6,
    );

    final content = Column(
      children: [
        WelcomeGlassCard(
          child: Text(
            'Find your perfect match',
            style: taglineStyle,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: AppSpacing.spacingMD),
        Text(
          'Connect with like-minded people in a safe, inclusive community designed for everyone.',
          style: bodyStyle,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.spacingLG),
        Text(
          'LGBTFinder',
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (!animated || _minimalFirstFrame) {
      return content;
    }

    return AnimatedBuilder(
      animation: _textAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _textAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _textAnimation.value)),
            child: child,
          ),
        );
      },
      child: content,
    );
  }

  Widget _buildLogo(BuildContext context, {required bool animated}) {
    final logo = Semantics(
      label: 'LGBTFinder logo',
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacingMD),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimaryDark.withValues(alpha: 0.35),
              blurRadius: 32,
            ),
            BoxShadow(
              color: AppColors.backgroundDark.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const LGBTFinderLogo(size: 72),
      ),
    );

    if (!animated || _minimalFirstFrame) {
      return logo;
    }

    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoAnimation.value,
          child: Opacity(
            opacity: _logoAnimation.value,
            child: child,
          ),
        );
      },
      child: logo,
    );
  }

  Widget _buildActions(BuildContext context, {required bool animated}) {
    final actions = Column(
      children: [
        Semantics(
          label: 'Create account',
          button: true,
          child: GradientButton(
            text: 'Create Account',
            onPressed: () => context.go(AppRoutes.register),
            usePrideGradient: true,
          ),
        ),
        SizedBox(height: AppSpacing.spacingLG),
        Semantics(
          label: 'Sign in',
          button: true,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton(
              onPressed: () => context.go(AppRoutes.login),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                ),
              ),
              child: Text(
                'Sign In',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.spacingLG),
      ],
    );

    if (!animated || _minimalFirstFrame) {
      return actions;
    }

    return AnimatedBuilder(
      animation: _buttonAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _buttonAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _buttonAnimation.value)),
            child: child,
          ),
        );
      },
      child: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      _buildCount++;
      screenLog('WelcomeScreen', 'build #$_buildCount');
    }

    if (!_precacheScheduled && context.mounted) {
      _precacheScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        precacheImage(const AssetImage(LGBTFinderLogo.assetPath), context);
      });
    }

    final size = MediaQuery.of(context).size;
    final mosaicHeight = size.height * 0.32;
    final animated = !_minimalFirstFrame;

    return Scaffold(
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.brandGradient),
          ),
          if (_showFloatingShapes && !kDebugMode)
            RepaintBoundary(
              child: Stack(
                children: [
                  Positioned(
                    top: size.height * 0.12,
                    left: size.width * 0.08,
                    child: _FloatingShape(
                      size: 64,
                      color: AppColors.textPrimaryDark.withValues(alpha: 0.1),
                      animation: _floatingAnimation,
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.42,
                    right: size.width * 0.1,
                    child: _FloatingShape(
                      size: 48,
                      color: AppColors.textPrimaryDark.withValues(alpha: 0.08),
                      animation: _floatingAnimation,
                      phaseOffset: 2 * math.pi / 3,
                    ),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingXL,
                vertical: AppSpacing.spacingLG,
              ),
              child: Column(
                children: [
                  WelcomeProfileMosaic(maxHeight: mosaicHeight.clamp(160, 260)),
                  SizedBox(height: AppSpacing.spacingLG),
                  _buildLogo(context, animated: animated),
                  SizedBox(height: AppSpacing.spacingMD),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: _buildBrandingBlock(context, animated: animated),
                    ),
                  ),
                  _buildActions(context, animated: animated),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
            ),
          ),
        );
      },
    );
  }
}
