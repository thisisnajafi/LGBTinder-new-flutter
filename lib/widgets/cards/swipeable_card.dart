// Widget: SwipeableCard
// Swipeable card component for discovery (REF-02 / Klick full-bleed layout)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/profile_image_widget.dart';

/// Profile card for discovery — full-bleed photo with bottom gradient overlay.
class SwipeableCard extends ConsumerStatefulWidget {
  final int userId;
  final String name;
  final int? age;
  final String? location;
  final String? avatarUrl;
  final List<String>? imageUrls;
  final String? bio;
  final bool isVerified;
  final bool isPremium;
  final double? distance;
  final int? compatibilityScore;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onSuperlike;
  final VoidCallback? onTap;
  /// When true, only the photo is shown (stack cards behind the active card).
  final bool isBackgroundPreview;

  const SwipeableCard({
    super.key,
    required this.userId,
    required this.name,
    this.age,
    this.location,
    this.avatarUrl,
    this.imageUrls,
    this.bio,
    this.isVerified = false,
    this.isPremium = false,
    this.distance,
    this.compatibilityScore,
    this.onLike,
    this.onDislike,
    this.onSuperlike,
    this.onTap,
    this.isBackgroundPreview = false,
  });

  static const double cardRadius = 20;

  @override
  ConsumerState<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends ConsumerState<SwipeableCard> {
  int _currentImageIndex = 0;

  void _cycleImage(int delta, int imageCount) {
    if (imageCount <= 1) return;
    setState(() {
      _currentImageIndex = (_currentImageIndex + delta) % imageCount;
      if (_currentImageIndex < 0) _currentImageIndex += imageCount;
    });
  }

  String _distanceLabel() {
    if (widget.distance != null) {
      return '${widget.distance!.round()} km away';
    }
    if (widget.location != null && widget.location!.isNotEmpty) {
      return widget.location!;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images =
        widget.imageUrls ?? (widget.avatarUrl != null ? [widget.avatarUrl!] : []);
    final currentImage = images.isNotEmpty ? images[_currentImageIndex] : null;
    final nameLine = widget.age != null
        ? '${widget.name}, ${widget.age}'
        : widget.name;
    final distanceLabel = _distanceLabel();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingSM),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(SwipeableCard.cardRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (currentImage != null)
                ProfileImageWidget(
                  imageUrl: currentImage,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                )
              else
                ColoredBox(
                  color: theme.colorScheme.surface,
                  child: Center(
                    child: AppSvgIcon(
                      assetPath: AppIcons.userOutline,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 200,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.78),
                      ],
                    ),
                  ),
                ),
              ),
              if (distanceLabel.isNotEmpty && !widget.isBackgroundPreview)
                Positioned(
                  top: AppSpacing.spacingMD,
                  right: AppSpacing.spacingMD,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingMD,
                      vertical: AppSpacing.spacingSM,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSvgIcon(
                          assetPath: AppIcons.location,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: AppSpacing.spacingXS),
                        Text(
                          distanceLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!widget.isBackgroundPreview)
                Positioned(
                  left: AppSpacing.spacingLG,
                  right: AppSpacing.spacingLG,
                  bottom: AppSpacing.spacingLG,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              nameLine,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.isVerified) ...[
                            const SizedBox(width: AppSpacing.spacingXS),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: AppSvgIcon(
                                assetPath: AppIcons.check,
                                size: 11,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (widget.bio != null && widget.bio!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.spacingXS),
                        Text(
                          widget.bio!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (!widget.isBackgroundPreview && images.length > 1)
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => _cycleImage(-1, images.length),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => _cycleImage(1, images.length),
                        ),
                      ),
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
