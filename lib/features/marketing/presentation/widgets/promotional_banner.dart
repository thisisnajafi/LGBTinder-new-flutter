import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/banner_model.dart';
import '../../providers/marketing_providers.dart';

/// Promotional banner widget
/// Supports hero, interstitial, sticky, and popup banner types
/// Part of the Marketing System Implementation (Task 3.4.1)
class PromotionalBanner extends ConsumerStatefulWidget {
  final BannerModel banner;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;

  const PromotionalBanner({
    Key? key,
    required this.banner,
    this.onDismiss,
    this.onAction,
  }) : super(key: key);

  @override
  ConsumerState<PromotionalBanner> createState() => _PromotionalBannerState();
}

class _PromotionalBannerState extends ConsumerState<PromotionalBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasTrackedImpression = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    _trackImpression();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _trackImpression() async {
    if (_hasTrackedImpression) return;
    _hasTrackedImpression = true;

    try {
      final bannerService = ref.read(bannerServiceProvider);
      await bannerService.trackImpression(widget.banner.id);
    } catch (_) {
      // Silently fail - tracking shouldn't block UX
    }
  }

  Future<void> _handleAction() async {
    try {
      final bannerService = ref.read(bannerServiceProvider);
      await bannerService.trackClick(widget.banner.id);
    } catch (_) {
      // Silently fail
    }

    if (widget.onAction != null) {
      widget.onAction!();
      return;
    }

    // Handle action based on type
    final actionType = widget.banner.actionType;
    final actionUrl = widget.banner.actionUrl;
    final actionData = widget.banner.actionData;

    switch (actionType) {
      case 'screen':
        if (actionUrl != null && mounted) {
          context.push(actionUrl);
        }
        break;
      case 'url':
        // Could use url_launcher here
        break;
      case 'promotion':
        if (actionData != null && mounted) {
          final promoCode = actionData['promo_code'];
          if (promoCode != null) {
            context.push('/plans?promo=$promoCode');
          }
        }
        break;
      case 'plan':
        if (actionData != null && mounted) {
          final planId = actionData['plan_id'];
          context.push('/plans${planId != null ? '?plan=$planId' : ''}');
        }
        break;
    }
  }

  Future<void> _handleDismiss() async {
    await _animationController.reverse();

    try {
      final bannerService = ref.read(bannerServiceProvider);
      await bannerService.dismissBanner(widget.banner.id);
    } catch (_) {
      // Silently fail
    }

    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.banner.bannerType) {
      case 'hero':
        return _buildHeroBanner(context);
      case 'interstitial':
        return _buildInterstitialBanner(context);
      case 'sticky':
        return _buildStickyBanner(context);
      case 'popup':
        return _buildPopupBanner(context);
      default:
        return _buildHeroBanner(context);
    }
  }

  Widget _buildHeroBanner(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppColors.accentPurple,
                AppColors.accentGradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurple.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleAction,
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Background image if present
                  if (widget.banner.imageUrl != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: widget.banner.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.banner.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.banner.subtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.banner.subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _handleAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.accentPurple,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            widget.banner.actionData?['cta_text'] ?? 'Learn More',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dismiss button
                  if (widget.banner.isDismissible)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: _handleDismiss,
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterstitialBanner(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accentPurple.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Icon or image
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentPurple,
                    AppColors.accentGradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.banner.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: widget.banner.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.local_offer,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.local_offer, color: Colors.white),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.banner.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.banner.subtitle != null)
                    Text(
                      widget.banner.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Action
            TextButton(
              onPressed: _handleAction,
              child: Text(
                widget.banner.actionData?['cta_text'] ?? 'View',
                style: TextStyle(
                  color: AppColors.accentPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Dismiss
            if (widget.banner.isDismissible)
              IconButton(
                onPressed: _handleDismiss,
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyBanner(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentPurple,
              AppColors.accentGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.banner.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.banner.subtitle != null)
                      Text(
                        widget.banner.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _handleAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.accentPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 36),
                ),
                child: Text(
                  widget.banner.actionData?['cta_text'] ?? 'Get',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (widget.banner.isDismissible)
                IconButton(
                  onPressed: _handleDismiss,
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  padding: const EdgeInsets.only(left: 8),
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupBanner(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentPurple,
                      AppColors.accentGradientEnd,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    if (widget.banner.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: widget.banner.imageUrl!,
                          height: 100,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) => const Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 48,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      widget.banner.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (widget.banner.subtitle != null)
                      Text(
                        widget.banner.subtitle!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.banner.actionData?['cta_text'] ?? 'Claim Now',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    if (widget.banner.isDismissible) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _handleDismiss,
                        child: Text(
                          'Not now',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper widget to show popup banner as a dialog
class PopupBannerDialog extends StatelessWidget {
  final BannerModel banner;

  const PopupBannerDialog({Key? key, required this.banner}) : super(key: key);

  static Future<void> show(BuildContext context, BannerModel banner) {
    return showDialog(
      context: context,
      barrierDismissible: banner.isDismissible,
      builder: (context) => PopupBannerDialog(banner: banner),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: PromotionalBanner(
        banner: banner,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }
}
