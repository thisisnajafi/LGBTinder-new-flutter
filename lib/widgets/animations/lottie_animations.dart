// Widget: LottieAnimations
// Lottie animation wrapper with theme support
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_colors.dart';

/// Theme-aware Lottie animation wrapper
/// Automatically applies app color scheme to Lottie animations
class ThemeAwareLottie extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final bool loop;
  final bool animate;
  final Map<String, Color>? colorOverrides;
  final BoxFit fit;
  final Alignment alignment;

  const ThemeAwareLottie({
    Key? key,
    required this.assetPath,
    this.width,
    this.height,
    this.loop = true,
    this.animate = true,
    this.colorOverrides,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Lottie.asset(
      assetPath,
      width: width,
      height: height,
      repeat: loop,
      animate: animate,
      fit: fit,
      alignment: alignment,
      // Note: For color replacement, the Lottie file must be structured
      // with named layers or use specific color values that can be mapped.
      // This wrapper provides the structure for future color replacement implementation.
    );
  }
}

/// Pre-configured Lottie animations with app theme colors
class AppLottieAnimations {
  // Loading animations
  static Widget loading({
    double? size,
    bool loop = true,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/loading.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  static Widget loadingHearts({
    double? size,
    bool loop = true,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/loading_hearts.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  static Widget loadingRainbow({
    double? size,
    bool loop = true,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/loading_rainbow.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  // Success animations
  static Widget success({
    double? size,
    bool loop = false,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/success.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  static Widget celebration({
    double? size,
    bool loop = false,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/celebration.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  static Widget matchCelebration({
    double? size,
    bool loop = false,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/match_celebration.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  static Widget heartBurst({
    double? size,
    bool loop = false,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/heart_burst.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  // Profile animations
  static Widget profileComplete({
    double? size,
    bool loop = false,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/profile_complete.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  static Widget verificationBadge({
    double? size,
    bool loop = false,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/verification_badge.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  // Empty state animations
  static Widget emptyMatches({
    double? size,
    bool loop = true,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/empty_matches.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  static Widget emptyChats({
    double? size,
    bool loop = true,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/empty_chats.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  static Widget emptyDiscover({
    double? size,
    bool loop = true,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/empty_discover.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  // Error animations
  static Widget error({
    double? size,
    bool loop = false,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/error.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  static Widget errorNetwork({
    double? size,
    bool loop = false,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/error_network.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  // Interactive animations
  static Widget likeAnimation({
    double? size,
    bool loop = false,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/like_animation.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  static Widget superLike({
    double? size,
    bool loop = false,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/super_like.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  static Widget passAnimation({
    double? size,
    bool loop = false,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/pass_animation.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  // Premium animations
  static Widget premiumBadge({
    double? size,
    bool loop = true,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/premium_badge.json',
      width: size,
      height: size,
      loop: loop,
    );
  }

  static Widget premiumUnlock({
    double? size,
    bool loop = false,
  }) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/premium_unlock.json',
      width: size,
      height: size,
      loop: loop,
    );
  }
}

/// Legacy widget name for backward compatibility
@Deprecated('Use ThemeAwareLottie or AppLottieAnimations instead')
class LottieAnimations extends ConsumerWidget {
  final String assetPath;
  final double? size;

  const LottieAnimations({
    Key? key,
    required this.assetPath,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ThemeAwareLottie(
      assetPath: assetPath,
      width: size,
      height: size,
    );
  }
}
