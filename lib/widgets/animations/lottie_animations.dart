// Widget: LottieAnimations
// Lottie wrapper with safe fallback when assets are missing (prevents startup hangs).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_colors.dart';

/// Theme-aware Lottie animation with [CircularProgressIndicator] fallback.
class ThemeAwareLottie extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final bool loop;
  final bool animate;
  final BoxFit fit;
  final Alignment alignment;

  const ThemeAwareLottie({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.loop = true,
    this.animate = true,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  double get _fallbackSize => width ?? height ?? 48;

  Widget _fallbackSpinner() {
    return SizedBox(
      width: _fallbackSize,
      height: _fallbackSize,
      child: const CircularProgressIndicator(
        color: AppColors.accentPurple,
        strokeWidth: 3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return _fallbackSpinner();
    }

    return Lottie.asset(
      assetPath,
      width: width,
      height: height,
      repeat: loop,
      animate: animate,
      fit: fit,
      alignment: alignment,
      frameBuilder: (context, child, composition) {
        if (composition == null) {
          return _fallbackSpinner();
        }
        return child;
      },
      errorBuilder: (_, __, ___) => _fallbackSpinner(),
    );
  }
}

/// Pre-configured Lottie animations — fall back to spinner if JSON is not bundled.
class AppLottieAnimations {
  static Widget loading({double size = 48}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/loading.json',
      width: size,
      height: size,
    );
  }

  static Widget loadingHearts({double size = 48}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/loading_hearts.json',
      width: size,
      height: size,
    );
  }

  static Widget loadingRainbow({double size = 48}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/loading_rainbow.json',
      width: size,
      height: size,
    );
  }

  static Widget success({double size = 120}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/success.json',
      width: size,
      height: size,
      loop: false,
    );
  }

  static Widget celebration({double size = 200}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/celebration.json',
      width: size,
      height: size,
      loop: false,
    );
  }

  static Widget matchCelebration({double size = 200}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/match_celebration.json',
      width: size,
      height: size,
      loop: false,
    );
  }

  static Widget heartBurst({double size = 100}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/heart_burst.json',
      width: size,
      height: size,
      loop: false,
    );
  }

  static Widget profileComplete({double size = 120}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/profile_complete.json',
      width: size,
      height: size,
      loop: false,
    );
  }

  static Widget verificationBadge({double size = 80}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/verification_badge.json',
      width: size,
      height: size,
      loop: false,
    );
  }

  static Widget emptyMatches({double size = 160}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/empty_matches.json',
      width: size,
      height: size,
    );
  }

  static Widget emptyChats({double size = 160}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/empty_chats.json',
      width: size,
      height: size,
    );
  }

  static Widget emptyDiscover({double size = 160}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/empty_discover.json',
      width: size,
      height: size,
    );
  }

  static Widget error({double size = 120}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/error.json',
      width: size,
      height: size,
    );
  }

  static Widget errorNetwork({double size = 120}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/error_network.json',
      width: size,
      height: size,
    );
  }

  static Widget likeAnimation({double size = 80}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/like_animation.json',
      width: size,
      height: size,
      loop: false,
    );
  }

  static Widget superLike({double size = 80}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/super_like.json',
      width: size,
      height: size,
      loop: false,
    );
  }

  static Widget passAnimation({double size = 80}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/pass_animation.json',
      width: size,
      height: size,
      loop: false,
    );
  }

  static Widget premiumBadge({double size = 64}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/premium_badge.json',
      width: size,
      height: size,
    );
  }

  static Widget premiumUnlock({double size = 120}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/premium_unlock.json',
      width: size,
      height: size,
      loop: false,
    );
  }
}

@Deprecated('Use ThemeAwareLottie or AppLottieAnimations instead')
class LottieAnimations extends ConsumerWidget {
  final String assetPath;
  final double? size;

  const LottieAnimations({
    super.key,
    required this.assetPath,
    this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ThemeAwareLottie(
      assetPath: assetPath,
      width: size,
      height: size,
    );
  }
}
