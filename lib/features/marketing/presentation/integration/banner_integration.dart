import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/banner_model.dart';
import '../../providers/marketing_providers.dart';
import '../widgets/promotional_banner.dart';

/// Banner integration widget for displaying banners on any screen
/// Part of the Marketing System Implementation (Task 3.6.1)
/// 
/// Usage:
/// ```dart
/// Column(
///   children: [
///     BannerIntegration.hero(position: 'home'),
///     // ... other content
///     BannerIntegration.sticky(position: 'home'),
///   ],
/// )
/// ```
class BannerIntegration extends ConsumerWidget {
  final String position;
  final String? bannerType;
  final Widget? placeholder;
  final EdgeInsets padding;

  const BannerIntegration({
    Key? key,
    required this.position,
    this.bannerType,
    this.placeholder,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  /// Hero banner at top of screen
  factory BannerIntegration.hero({
    required String position,
    EdgeInsets padding = const EdgeInsets.only(bottom: 16),
  }) {
    return BannerIntegration(
      position: position,
      bannerType: 'hero',
      padding: padding,
    );
  }

  /// Interstitial banner between content
  factory BannerIntegration.interstitial({
    required String position,
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 8),
  }) {
    return BannerIntegration(
      position: position,
      bannerType: 'interstitial',
      padding: padding,
    );
  }

  /// Sticky banner at bottom
  factory BannerIntegration.sticky({
    required String position,
  }) {
    return BannerIntegration(
      position: position,
      bannerType: 'sticky',
      padding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannersByPositionProvider(position));

    return bannersAsync.when(
      loading: () => placeholder ?? const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        // Filter by type if specified
        final filteredBanners = bannerType != null
            ? banners.where((b) => b.bannerType == bannerType).toList()
            : banners;

        if (filteredBanners.isEmpty) return const SizedBox.shrink();

        // Get highest priority banner
        final banner = filteredBanners.first;

        return Padding(
          padding: padding,
          child: PromotionalBanner(
            banner: banner,
            onDismiss: () {
              // Refresh banners after dismiss
              ref.invalidate(bannersByPositionProvider(position));
            },
          ),
        );
      },
    );
  }
}

/// Mixin for screens that want to show interstitial banners after actions
/// Part of the Marketing System Implementation (Task 3.6.1)
/// 
/// Usage:
/// ```dart
/// class _MyScreenState extends ConsumerState<MyScreen> 
///     with InterstitialBannerMixin {
///   
///   void _onSwipe() {
///     incrementSwipeCount();
///     checkAndShowInterstitial(context, 'discover');
///   }
/// }
/// ```
mixin InterstitialBannerMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  int _swipeCount = 0;
  int _interstitialThreshold = 10; // Show after X swipes
  bool _hasShownInterstitial = false;

  /// Set the threshold for showing interstitial
  void setInterstitialThreshold(int threshold) {
    _interstitialThreshold = threshold;
  }

  /// Increment swipe/action count
  void incrementSwipeCount() {
    _swipeCount++;
  }

  /// Reset swipe count
  void resetSwipeCount() {
    _swipeCount = 0;
    _hasShownInterstitial = false;
  }

  /// Check if should show interstitial and show it
  Future<void> checkAndShowInterstitial(BuildContext context, String position) async {
    if (_hasShownInterstitial) return;
    if (_swipeCount < _interstitialThreshold) return;

    final banners = await ref.read(bannersByPositionProvider(position).future);
    final interstitial = banners.firstWhere(
      (b) => b.bannerType == 'interstitial' || b.bannerType == 'popup',
      orElse: () => null as dynamic,
    );

    if (interstitial != null && mounted) {
      _hasShownInterstitial = true;
      await PopupBannerDialog.show(context, interstitial);
    }
  }

  /// Show a popup banner immediately
  Future<void> showPopupBanner(BuildContext context, String position) async {
    final banners = await ref.read(bannersByPositionProvider(position).future);
    final popup = banners.firstWhere(
      (b) => b.bannerType == 'popup',
      orElse: () => null as dynamic,
    );

    if (popup != null && mounted) {
      await PopupBannerDialog.show(context, popup);
    }
  }
}

/// Widget that shows sticky banner at bottom of scaffold
/// Part of the Marketing System Implementation (Task 3.6.1)
/// 
/// Usage:
/// ```dart
/// Scaffold(
///   body: ...,
///   bottomNavigationBar: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       StickyBannerWrapper(position: 'home'),
///       BottomNavigationBar(...),
///     ],
///   ),
/// )
/// ```
class StickyBannerWrapper extends ConsumerWidget {
  final String position;

  const StickyBannerWrapper({
    Key? key,
    required this.position,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannersByPositionProvider(position));

    return bannersAsync.maybeWhen(
      data: (banners) {
        final stickyBanner = banners.firstWhere(
          (b) => b.bannerType == 'sticky',
          orElse: () => null as dynamic,
        );

        if (stickyBanner == null) return const SizedBox.shrink();

        return PromotionalBanner(
          banner: stickyBanner,
          onDismiss: () {
            ref.invalidate(bannersByPositionProvider(position));
          },
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Extension to easily add banner to any scaffold
extension BannerScaffoldExtension on Scaffold {
  /// Wrap scaffold with hero banner at top
  Widget withHeroBanner(String position) {
    return Column(
      children: [
        BannerIntegration.hero(position: position),
        Expanded(child: this),
      ],
    );
  }
}
