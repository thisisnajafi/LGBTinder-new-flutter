// Screen: SplashPage
// Shows logo, then checks token via GET /auth/check-token. Valid → Home, invalid → Welcome.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../core/constants/animation_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/constants/api_endpoints.dart';
import '../core/providers/api_providers.dart';
import '../core/widgets/splash_arc_loader.dart';
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
    with SingleTickerProviderStateMixin {
  static const Duration _splashDelay = Duration(milliseconds: 400);
  static const Duration _tokenCheckTimeout = Duration(seconds: 4);
  static const Duration _absoluteMaxOnSplash = Duration(seconds: 8);

  bool _redirected = false;
  Timer? _absoluteEscapeTimer;
  late AnimationController _logoController;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    screenLog('SplashPage', 'initState');
    startupLog('SplashPage: scheduling auth check after first frame');

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutCubic,
      ),
    );

    _absoluteEscapeTimer = Timer(_absoluteMaxOnSplash, () {
      if (_redirected || !mounted) return;
      authLog('Splash: absolute timeout → welcome');
      _goToWelcome(ref.read(tokenStorageServiceProvider));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppAnimations.animationsEnabled(context)) {
        _logoController.forward();
      } else {
        _logoController.value = 1;
      }
      _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    _absoluteEscapeTimer?.cancel();
    _logoController.dispose();
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
        // Non-auth failures (e.g. 403 plan gate) — keep stored session.
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: RepaintBoundary(
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.prideGradient),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.spacingXL),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.backgroundDark.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const LGBTFinderLogo(size: 80),
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingXXL),
                  Text(
                    'LGBTFinder',
                    style: textTheme.displayLarge?.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  Text(
                    'Find your perfect match',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimaryDark.withValues(alpha: 0.85),
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingXXL),
                  const SplashArcLoader(
                    size: 44,
                    strokeWidth: 3,
                    color: AppColors.accentRose,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
