// Screen: AuthCheckScreen
// Single route that checks token + API; redirects to welcome (not logged in) or home (logged in).
// Keeps splash free of I/O and avoids stuck splash.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/theme/spacing_constants.dart';
import '../../routes/app_router.dart';
import '../../core/providers/api_providers.dart';
import '../../widgets/loading/circular_progress.dart';
import '../../widgets/navbar/lgbtfinder_logo.dart';

/// Auth check: if no token or API says not authenticated → welcome; else → home.
class AuthCheckScreen extends ConsumerStatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends ConsumerState<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAndRedirect();
    });
  }

  Future<void> _checkAndRedirect() async {
    final tokenStorage = ref.read(tokenStorageServiceProvider);
    final dioClient = ref.read(dioClientProvider);

    try {
      // 1) Token exists?
      final hasToken = await tokenStorage.isAuthenticated().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );

      if (!mounted) return;
      if (!hasToken) {
        await tokenStorage.clearAllTokens();
        context.go(AppRoutes.welcome);
        return;
      }

      // 2) Validate token with API (e.g. GET /user or /profile)
      try {
        final response = await dioClient.dio.get(ApiEndpoints.user).timeout(
          const Duration(seconds: 5),
        );

        if (!mounted) return;
        if (response.statusCode == 200 || (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300)) {
          context.go(AppRoutes.home);
          return;
        }
        // 4xx (e.g. 401) or other → not authenticated
        await tokenStorage.clearAllTokens();
        if (mounted) context.go(AppRoutes.welcome);
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (!mounted) return;
        if (status == 401 || status == 403) {
          await tokenStorage.clearAllTokens();
        }
        if (mounted) context.go(AppRoutes.welcome);
      }
    } catch (_) {
      if (!mounted) return;
      await tokenStorage.clearAllTokens();
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFE40303),
        const Color(0xFFFF8C00),
        const Color(0xFFFFED00),
        const Color(0xFF008026),
        const Color(0xFF004DFF),
        const Color(0xFF750787),
      ],
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
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
                  'Checking…',
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
