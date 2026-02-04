// Screen: SplashPage
// No I/O here — only a short delay then navigate. Auth/route logic runs on Welcome to avoid ANR.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../widgets/loading/circular_progress.dart';
import '../widgets/navbar/lgbtfinder_logo.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_router.dart';

/// Splash: show logo briefly, then go to auth-check. Auth-check validates token and redirects to welcome or home.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  /// Only delay + go to auth-check. No I/O here — prevents ANR.
  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    context.go(AppRoutes.authCheck);
  }

  @override
  Widget build(BuildContext context) {
    final rainbowGradient = LinearGradient(
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
        decoration: BoxDecoration(gradient: rainbowGradient),
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
