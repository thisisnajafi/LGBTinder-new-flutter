// Lottie wrapper: lazy mount, one composition at a time, Reduce Motion fallback.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';

/// Caps how many Lottie files decode/play at once (PERF-COMP-ANIM-002).
class LottiePlaybackLimiter {
  LottiePlaybackLimiter._();

  static const int maxConcurrent = 1;
  static int _active = 0;

  static bool tryAcquire() {
    if (_active >= maxConcurrent) return false;
    _active++;
    return true;
  }

  static void release() {
    if (_active > 0) _active--;
  }

  @visibleForTesting
  static int get debugActiveCount => _active;

  @visibleForTesting
  static void debugReset() {
    _active = 0;
  }
}

/// Theme-aware Lottie. Composition is not mounted until after the first frame
/// (PERF-COMP-ANIM-001), and only if a [LottiePlaybackLimiter] slot is free.
class ThemeAwareLottie extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final bool loop;
  final bool animate;
  final Widget? fallback;
  final BoxFit fit;
  final Alignment alignment;

  const ThemeAwareLottie({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.loop = true,
    this.animate = true,
    this.fallback,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  @override
  State<ThemeAwareLottie> createState() => _ThemeAwareLottieState();
}

class _ThemeAwareLottieState extends State<ThemeAwareLottie> {
  bool _holdsSlot = false;
  bool _showLottie = false;

  double get _fallbackSize => widget.width ?? widget.height ?? 48;

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

  Widget _resolvedFallback() => widget.fallback ?? _fallbackSpinner();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPlayback());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPlayback());
  }

  @override
  void didUpdateWidget(covariant ThemeAwareLottie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath ||
        oldWidget.animate != widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncPlayback());
    }
  }

  void _syncPlayback() {
    if (!mounted) return;
    final allow = widget.animate &&
        AppAnimations.animationsEnabled(context) &&
        TickerMode.valuesOf(context).enabled;
    if (!allow) {
      _releaseSlot();
      if (_showLottie) {
        setState(() => _showLottie = false);
      }
      return;
    }
    if (_showLottie) return;
    if (!_holdsSlot && !LottiePlaybackLimiter.tryAcquire()) return;
    _holdsSlot = true;
    setState(() => _showLottie = true);
  }

  void _releaseSlot() {
    if (!_holdsSlot) return;
    LottiePlaybackLimiter.release();
    _holdsSlot = false;
  }

  @override
  void dispose() {
    _releaseSlot();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showLottie) return _resolvedFallback();

    return Lottie.asset(
      widget.assetPath,
      width: widget.width,
      height: widget.height,
      repeat: widget.loop,
      animate: widget.animate,
      fit: widget.fit,
      alignment: widget.alignment,
      frameBuilder: (context, child, composition) {
        if (composition == null) {
          return _resolvedFallback();
        }
        return child;
      },
      errorBuilder: (_, __, ___) => _resolvedFallback(),
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

  static Widget chatHeart({double size = 140, Widget? fallback}) {
    return ThemeAwareLottie(
      assetPath: 'assets/lottie/chat_heart.json',
      width: size,
      height: size,
      fallback: fallback,
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
