// Screen: WelcomeScreen
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../features/onboarding/widgets/welcome_glass_card.dart';
import '../../features/onboarding/widgets/welcome_value_props.dart';
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
  late AnimationController _entranceController;
  late AnimationController _ambientController;

  late Animation<double> _mosaicFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late Animation<Offset> _actionsSlide;
  late Animation<double> _actionsFade;
  late Animation<double> _ambientPulse;

  bool _minimalFirstFrame = true;
  bool _fullUIScheduled = false;
  bool _precacheScheduled = false;
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    screenLog('WelcomeScreen', 'initState');
    startupLog('WelcomeScreen: reached WELCOME');

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _ambientController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _mosaicFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 45),
    ]).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.12, 0.55, curve: Curves.easeOut),
    ));

    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.12, 0.48, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.32, 0.68, curve: Curves.easeOutCubic),
    ));

    _textFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.32, 0.68, curve: Curves.easeOutCubic),
    );

    _actionsSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.48, 0.88, curve: Curves.easeOutCubic),
    ));

    _actionsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.48, 0.88, curve: Curves.easeOutCubic),
    );

    _ambientPulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _fullUIScheduled) return;
      _fullUIScheduled = true;
      setState(() => _minimalFirstFrame = false);

      if (!AppAnimations.animationsEnabled(context)) {
        _entranceController.value = 1;
        return;
      }

      _entranceController.forward();
      _ambientController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  TextStyle _whiteText(BuildContext context, TextStyle? base,
      {FontWeight? weight, double? size, double alpha = 1.0}) {
    return (base ?? Theme.of(context).textTheme.bodyLarge!).copyWith(
      fontFamily: 'Inter',
      color: Colors.white.withValues(alpha: alpha),
      fontWeight: weight,
      fontSize: size,
    );
  }

  Widget _buildBrandingBlock(BuildContext context, {required bool animated}) {
    final textTheme = Theme.of(context).textTheme;

    final content = Column(
      children: [
        WelcomeGlassCard(
          onGradient: true,
          child: Text(
            'Find your perfect match',
            style: _whiteText(
              context,
              textTheme.headlineSmall,
              weight: FontWeight.w700,
              size: 22,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: AppSpacing.spacingMD),
        Text(
          'Connect with like-minded people in a safe, inclusive community designed for everyone.',
          style: _whiteText(
            context,
            textTheme.bodyLarge,
            alpha: 0.82,
          ).copyWith(height: 1.55, letterSpacing: 0.15),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.spacingLG),
        Text(
          'LGBTFinder',
          style: _whiteText(
            context,
            textTheme.displaySmall,
            weight: FontWeight.w800,
            size: 34,
          ).copyWith(letterSpacing: 0.6),
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (!animated || _minimalFirstFrame) {
      return content;
    }

    return SlideTransition(
      position: _textSlide,
      child: FadeTransition(opacity: _textFade, child: content),
    );
  }

  Widget _buildLogoBadge(double logoSize) {
    final glowSize = logoSize * 1.15;
    final circleSize = logoSize;
    final heartSize = logoSize * 0.52;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: glowSize,
          height: glowSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              LGBTFinderLogo.assetPath,
              width: heartSize,
              height: heartSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(BuildContext context, {required bool animated}) {
    final width = MediaQuery.sizeOf(context).width;
    final logoSize = (width * 0.26).clamp(100.0, 120.0);

    final logo = Semantics(
      label: 'LGBTFinder logo',
      child: _buildLogoBadge(logoSize),
    );

    if (!animated || _minimalFirstFrame) {
      return logo;
    }

    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(scale: _logoScale, child: logo),
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
            onPressed: () => context.push(AppRoutes.register),
            usePrideGradient: true,
            height: 56,
          ),
        ),
        SizedBox(height: AppSpacing.spacingMD),
        Semantics(
          label: 'Sign in',
          button: true,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => context.push(AppRoutes.login),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                ),
              ),
              child: Text(
                'Sign In',
                style: _whiteText(
                  context,
                  Theme.of(context).textTheme.labelLarge,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.spacingMD),
      ],
    );

    if (!animated || _minimalFirstFrame) {
      return actions;
    }

    return SlideTransition(
      position: _actionsSlide,
      child: FadeTransition(opacity: _actionsFade, child: actions),
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
    final animated = !_minimalFirstFrame;
    final animationsEnabled = AppAnimations.animationsEnabled(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.splashGradient),
              child: SizedBox.expand(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: size.height * 0.42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.18),
                    ],
                  ),
                ),
              ),
            ),
            if (animationsEnabled)
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _ambientPulse,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned(
                          top: size.height * 0.08,
                          right: -size.width * 0.12,
                          child: Transform.scale(
                            scale: _ambientPulse.value,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: size.height * 0.22,
                          left: -size.width * 0.08,
                          child: Transform.scale(
                            scale: 2 - _ambientPulse.value,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingXL,
                  vertical: AppSpacing.spacingMD,
                ),
                child: Column(
                  children: [
                    SizedBox(height: AppSpacing.spacingLG),
                    FadeTransition(
                      opacity: animated ? _mosaicFade : const AlwaysStoppedAnimation(1),
                      child: const WelcomeValueProps(),
                    ),
                    SizedBox(height: AppSpacing.spacingXL),
                    _buildLogo(context, animated: animated),
                    SizedBox(height: AppSpacing.spacingMD),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: _buildBrandingBlock(
                          context,
                          animated: animated,
                        ),
                      ),
                    ),
                    _buildActions(context, animated: animated),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
