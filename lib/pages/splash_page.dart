// Screen: SplashPage
// Shows logo, then checks token via GET /auth/check-token. Valid → Home, invalid → Welcome.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/constants/animation_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/api_endpoints.dart';
import '../core/providers/api_providers.dart';
import '../shared/services/token_storage_service.dart';
import '../shared/services/onboarding_service.dart';
import '../widgets/navbar/lgbtfinder_logo.dart';
import '../routes/app_router.dart';
import '../core/utils/app_logger.dart';

/// Splash: paint immediately, then auth check off the first frame (avoids ANR).
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  static const Duration _splashDelay = Duration(milliseconds: 400);
  static const Duration _tokenCheckTimeout = Duration(seconds: 4);
  static const Duration _absoluteMaxOnSplash = Duration(seconds: 8);

  bool _redirected = false;
  bool _dotsStarted = false;
  Timer? _absoluteEscapeTimer;
  Timer? _dotsDelayTimer;

  late AnimationController _logoController;
  late AnimationController _dotsController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _dotsFade;

  late Animation<double> _dot1Anim;
  late Animation<double> _dot2Anim;
  late Animation<double> _dot3Anim;

  final Future<PackageInfo> _packageInfoFuture = PackageInfo.fromPlatform();

  @override
  void initState() {
    super.initState();
    screenLog('SplashPage', 'initState');
    startupLog('SplashPage: scheduling auth check after first frame');

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 16,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 42),
    ]).animate(_logoController);

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.35, 0.70, curve: Curves.easeOutCubic),
    ));

    _titleFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.35, 0.70, curve: Curves.easeOutCubic),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.45, 0.78, curve: Curves.easeOutCubic),
    ));

    _taglineFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.45, 0.78, curve: Curves.easeOutCubic),
    );

    _dotsFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.65, 0.85, curve: Curves.easeIn),
    );

    _dot1Anim = CurvedAnimation(
      parent: _dotsController,
      curve: const Interval(0.0, 0.4, curve: Curves.linear),
    );
    _dot2Anim = CurvedAnimation(
      parent: _dotsController,
      curve: const Interval(0.15, 0.55, curve: Curves.linear),
    );
    _dot3Anim = CurvedAnimation(
      parent: _dotsController,
      curve: const Interval(0.30, 0.70, curve: Curves.linear),
    );

    _logoController.addStatusListener(_onLogoAnimationStatus);

    _absoluteEscapeTimer = Timer(_absoluteMaxOnSplash, () {
      if (_redirected || !mounted) return;
      authLog('Splash: absolute timeout → welcome');
      _goToWelcome(ref.read(tokenStorageServiceProvider));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppAnimations.animationsEnabled(context)) {
        _logoController.forward();
        _dotsDelayTimer = Timer(const Duration(milliseconds: 900), _startDots);
      } else {
        _logoController.value = 1;
      }
      _checkAuthAndNavigate();
    });
  }

  void _onLogoAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _startDots();
    }
  }

  void _startDots() {
    if (_dotsStarted || !mounted) return;
    _dotsStarted = true;
    if (AppAnimations.animationsEnabled(context)) {
      _dotsController.repeat();
    }
  }

  @override
  void dispose() {
    _absoluteEscapeTimer?.cancel();
    _dotsDelayTimer?.cancel();
    _logoController.removeStatusListener(_onLogoAnimationStatus);
    _logoController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  void _goToOnboarding() {
    if (_redirected || !mounted) return;
    _redirected = true;
    _absoluteEscapeTimer?.cancel();
    markStartupFlowLeft();
    startupLog('Splash: first launch → intro onboarding');
    routeLog('go(${AppRoutes.onboarding})');
    context.go(AppRoutes.onboarding);
  }

  void _goToWelcome(
    TokenStorageService tokenStorage, {
    bool clearTokens = true,
  }) {
    if (_redirected || !mounted) return;
    _redirected = true;
    _absoluteEscapeTimer?.cancel();
    markStartupFlowLeft();
    authLog('Splash: no valid session → welcome (clearTokens=$clearTokens)');
    routeLog('go(${AppRoutes.welcome})');
    context.go(AppRoutes.welcome);
    if (clearTokens) {
      Future.microtask(() async {
        try {
          await tokenStorage.clearAllTokens();
        } catch (e) {
          AppLogger.warning(
            'Silently caught exception',
            tag: 'splash_page',
            error: e,
          );
        }
      });
    }
  }

  void _goToHome() {
    if (_redirected || !mounted) return;
    _redirected = true;
    _absoluteEscapeTimer?.cancel();
    markStartupFlowLeft();
    authLog('Splash: valid session → home');
    routeLog('go(${AppRoutes.home})');
    context.go(AppRoutes.home);
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      await Future.delayed(_splashDelay);
      if (!mounted || _redirected) return;
      startupLog('SplashPage: delay done');

      final onboardingService = OnboardingService();
      final hasSeenIntro = await onboardingService.hasSeenIntroOnboarding().timeout(
        const Duration(seconds: 2),
        onTimeout: () => true,
      );
      if (!mounted || _redirected) return;
      if (!hasSeenIntro) {
        _goToOnboarding();
        return;
      }

      final tokenStorage = ref.read(tokenStorageServiceProvider);
      final hasToken = await tokenStorage.isAuthenticated().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          authLog('Splash: token read timeout → treat as no token');
          return false;
        },
      );

      if (!mounted || _redirected) return;
      if (!hasToken) {
        apiLog('Splash: no token, skipping GET ${ApiEndpoints.checkToken}');
        _goToWelcome(tokenStorage);
        return;
      }

      apiLog('Splash: calling GET ${ApiEndpoints.checkToken}');
      try {
        final dioClient = ref.read(dioClientProvider);
        final response = await dioClient.dio
            .get(
              ApiEndpoints.checkToken,
              options: Options(
                sendTimeout: _tokenCheckTimeout,
                receiveTimeout: _tokenCheckTimeout,
              ),
            )
            .timeout(_tokenCheckTimeout);

        if (!mounted || _redirected) return;
        final code = response.statusCode ?? 0;
        authLog('Splash: check-token status=$code');
        if (code >= 200 && code < 300) {
          _goToHome();
          return;
        }
        if (code == 401) {
          _goToWelcome(tokenStorage);
          return;
        }
        authLog('Splash: check-token status=$code with token → home');
        _goToHome();
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (!mounted || _redirected) return;
        if (status == 401) {
          authLog('Splash: check-token 401 → welcome');
          _goToWelcome(tokenStorage);
          return;
        }
        authLog('Splash: check-token error status=$status with token → home');
        _goToHome();
      } on TimeoutException catch (_) {
        authLog('Splash: check-token timeout with token → home');
        if (!mounted || _redirected) return;
        _goToHome();
      } catch (e) {
        authLog('Splash: check-token exception $e with token → home');
        if (!mounted || _redirected) return;
        _goToHome();
      }
    } catch (_) {
      startupLog('SplashPage: bootstrap failed');
      if (mounted && !_redirected) {
        _goToWelcome(ref.read(tokenStorageServiceProvider));
      }
    }
  }

  double _pulseScale(double t) {
    if (t <= 0.0 || t >= 1.0) return 1.0;
    if (t <= 0.5) return 1.0 + t;
    return 1.5 - (t - 0.5);
  }

  Widget _buildLogoCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 124,
          height: 124,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              LGBTFinderLogo.assetPath,
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPulsingDots({required bool animationsEnabled}) {
    Widget dot(Animation<double> anim) {
      if (!animationsEnabled) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        );
      }
      return AnimatedBuilder(
        animation: anim,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseScale(anim.value),
            child: child,
          );
        },
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(_dot1Anim),
        const SizedBox(width: 8),
        dot(_dot2Anim),
        const SizedBox(width: 8),
        dot(_dot3Anim),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final animationsEnabled = AppAnimations.animationsEnabled(context);
    final titleFontSize = textTheme.displaySmall?.fontSize ?? 24.0;
    final taglineFontSize = textTheme.bodyLarge?.fontSize ?? 16.0;

    return Scaffold(
      body: RepaintBoundary(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.splashGradient,
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.30,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: _buildLogoCircle(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: Text(
                        'LGBTFinder',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SlideTransition(
                    position: _taglineSlide,
                    child: FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'Find your perfect match',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: taglineFontSize,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.82),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.12,
              left: 0,
              right: 0,
              child: Center(
                child: FadeTransition(
                  opacity: _dotsFade,
                  child: _buildPulsingDots(
                    animationsEnabled: animationsEnabled,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: FutureBuilder<PackageInfo>(
                future: _packageInfoFuture,
                builder: (context, snapshot) {
                  final version = snapshot.hasData
                      ? 'v${snapshot.data!.version}'
                      : 'v1.0.0';
                  return Text(
                    version,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
