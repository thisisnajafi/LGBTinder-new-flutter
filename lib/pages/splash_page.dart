// Screen: SplashPage
// Shows logo, then checks token via GET /auth/check-token. Valid → Home, invalid → Welcome.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/constants/api_endpoints.dart';
import '../core/providers/api_providers.dart';
import '../shared/services/token_storage_service.dart';
import '../shared/services/onboarding_service.dart';
import '../widgets/loading/circular_progress.dart';
import '../widgets/navbar/lgbtfinder_logo.dart';
import '../routes/app_router.dart';
import '../core/utils/app_logger.dart';

/// Splash: short delay, then token check (GET /auth/check-token). If valid → Home, else → Welcome.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  static const Duration _splashDelay = Duration(milliseconds: 600);
  static const Duration _tokenCheckTimeout = Duration(seconds: 4);
  static const Duration _guardTimeout = Duration(seconds: 5);

  bool _redirected = false;

  void _goToOnboarding() {
    if (_redirected || !mounted) return;
    _redirected = true;
    markStartupFlowLeft();
    startupLog('Splash: first launch → intro onboarding');
    routeLog('go(${AppRoutes.onboarding})');
    context.go(AppRoutes.onboarding);
  }

  void _goToWelcome(TokenStorageService tokenStorage) {
    if (_redirected || !mounted) return;
    _redirected = true;
    markStartupFlowLeft();
    authLog('Splash: no valid session → welcome');
    routeLog('go(${AppRoutes.welcome})');
    context.go(AppRoutes.welcome);
    Future.microtask(() async {
      try {
        await tokenStorage.clearAllTokens();
      } catch (_) {}
    });
  }

  void _goToHome() {
    if (_redirected || !mounted) return;
    _redirected = true;
    markStartupFlowLeft();
    authLog('Splash: valid session → home');
    routeLog('go(${AppRoutes.home})');
    context.go(AppRoutes.home);
  }

  @override
  void initState() {
    super.initState();
    screenLog('SplashPage', 'initState');
    startupLog('SplashPage: waiting ${_splashDelay.inMilliseconds}ms...');
    _checkAuthAndNavigate();
  }

  /// After delay: if first launch → Intro onboarding; else if no token → Welcome; else GET /auth/check-token → Home or Welcome.
  Future<void> _checkAuthAndNavigate() async {
    try {
      await Future.delayed(_splashDelay);
      if (!mounted) return;
      startupLog('SplashPage: delay done');

      final onboardingService = OnboardingService();
      final hasSeenIntro = await onboardingService.hasSeenIntroOnboarding().timeout(
        const Duration(seconds: 2),
        onTimeout: () => true,
      );
      if (!mounted || _redirected) return;
      if (!hasSeenIntro) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _goToOnboarding();
        });
        return;
      }

      final tokenStorage = ref.read(tokenStorageServiceProvider);
      final dioClient = ref.read(dioClientProvider);

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
        authLog('Splash: no token → welcome');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _goToWelcome(tokenStorage);
        });
        return;
      }

      apiLog('Splash: calling GET ${ApiEndpoints.checkToken}');
      // Guard: force welcome if we hang
      Future.delayed(_guardTimeout, () {
        if (_redirected || !mounted) return;
        authLog('Splash: guard timeout → welcome');
        if (mounted) _goToWelcome(tokenStorage);
      });

      try {
        final response = await dioClient.dio
            .get(ApiEndpoints.checkToken)
            .timeout(_tokenCheckTimeout);

        if (!mounted || _redirected) return;
        final code = response.statusCode ?? 0;
        authLog('Splash: check-token status=$code');
        if (code >= 200 && code < 300) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _goToHome();
          });
          return;
        }
        if (mounted) _goToWelcome(tokenStorage);
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        authLog('Splash: check-token error status=$status → welcome');
        if (!mounted || _redirected) return;
        if (status == 401 || status == 403) {
          Future.microtask(() async {
            try {
              await tokenStorage.clearAllTokens();
            } catch (_) {}
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _goToWelcome(tokenStorage);
        });
      } on TimeoutException catch (_) {
        authLog('Splash: check-token timeout → welcome');
        if (!mounted || _redirected) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _goToWelcome(tokenStorage);
        });
      } catch (e) {
        authLog('Splash: check-token exception $e → welcome');
        if (!mounted || _redirected) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _goToWelcome(tokenStorage);
        });
      }
    } catch (_) {
      startupLog('SplashPage: delay failed');
      if (mounted) {
        final tokenStorage = ref.read(tokenStorageServiceProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _goToWelcome(tokenStorage);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    screenLog('SplashPage', 'build');
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.prideGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacingXL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: LGBTFinderLogo(size: 80),
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                Text(
                  'LGBTFinder',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Text(
                  'Find your perfect match',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                CircularProgress(size: 40, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
