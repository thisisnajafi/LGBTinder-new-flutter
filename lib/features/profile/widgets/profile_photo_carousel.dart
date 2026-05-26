import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';

/// Full-width profile photo carousel with dots, count badge, and gallery viewer.
class ProfilePhotoCarousel extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final Widget? overlayHeader;
  final double aspectRatio;

  const ProfilePhotoCarousel({
    super.key,
    required this.imageUrls,
    this.overlayHeader,
    this.aspectRatio = 0.75,
  });

  @override
  ConsumerState<ProfilePhotoCarousel> createState() => _ProfilePhotoCarouselState();
}

class _ProfilePhotoCarouselState extends ConsumerState<ProfilePhotoCarousel> {
  late PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openGallery(int initialIndex) {
    if (widget.imageUrls.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _ProfilePhotoGallery(
          imageUrls: widget.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return const ProfilePhotoEmptyState();
    }

    final textTheme = Theme.of(context).textTheme;

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) {
              if (!mounted) return;
              setState(() => _index = i);
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return Semantics(
                label: 'Profile photo ${index + 1} of ${widget.imageUrls.length}',
                button: true,
                child: GestureDetector(
                  onTap: () => _openGallery(index),
                  child: Hero(
                    tag: 'profile_carousel_${widget.imageUrls[index]}_$index',
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrls[index],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => ColoredBox(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: Theme.of(context).colorScheme.surface,
                        child: Center(
                          child: Text(
                            'Photo unavailable',
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.backgroundDark.withValues(alpha: 0.55),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.spacingLG,
            right: AppSpacing.spacingLG,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingMD,
                vertical: AppSpacing.spacingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppRadius.radiusRound),
              ),
              child: Text(
                '${_index + 1}/${widget.imageUrls.length}',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (widget.overlayHeader != null)
            Positioned(
              left: AppSpacing.spacingLG,
              right: AppSpacing.spacingLG,
              bottom: AppSpacing.spacingXXL,
              child: widget.overlayHeader!,
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.spacingMD,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: widget.imageUrls.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 3,
                  spacing: AppSpacing.spacingXS,
                  activeDotColor: AppColors.accentPurple,
                  dotColor: AppColors.textPrimaryDark.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePhotoGallery extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ProfilePhotoGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: PhotoViewGallery.builder(
        itemCount: imageUrls.length,
        pageController: PageController(initialPage: initialIndex),
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(imageUrls[index]),
            minScale: PhotoViewComputedScale.contained,
            heroAttributes: PhotoViewHeroAttributes(
              tag: 'profile_carousel_${imageUrls[index]}_$index',
            ),
          );
        },
      ),
    );
  }
}

/// Empty photo placeholder for profile carousel area.
class ProfilePhotoEmptyState extends StatelessWidget {
  final VoidCallback? onAddPhoto;

  const ProfilePhotoEmptyState({super.key, this.onAddPhoto});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 0.75,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          border: Border.all(
            color: isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(
              assetPath: AppIcons.camera,
              size: 48,
              color: AppColors.accentPurple,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            Text(
              'Add your first photo',
              style: textTheme.titleMedium,
            ),
            if (onAddPhoto != null) ...[
              SizedBox(height: AppSpacing.spacingMD),
              InkWell(
                onTap: onAddPhoto,
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.spacingMD),
                  child: Text(
                    'Upload photo',
                    style: textTheme.labelLarge?.copyWith(color: AppColors.accentPurple),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
