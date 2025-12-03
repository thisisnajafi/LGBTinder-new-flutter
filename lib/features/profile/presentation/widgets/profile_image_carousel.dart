import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/user_image.dart';

/// Profile image carousel widget
/// Displays profile images in a horizontal scrollable carousel
class ProfileImageCarousel extends ConsumerWidget {
  final List<UserImage> images;
  final bool isEditable;
  final Function(int)? onDeleteImage;
  final Function(UserImage)? onImageTap;

  const ProfileImageCarousel({
    Key? key,
    required this.images,
    this.isEditable = false,
    this.onDeleteImage,
    this.onImageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_camera,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'No photos yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          return _buildImageItem(context, image, index);
        },
      ),
    );
  }

  Widget _buildImageItem(BuildContext context, UserImage image, int index) {
    final theme = Theme.of(context);

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          // Image container
          Container(
            width: 150,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: CachedNetworkImage(
                imageUrl: image.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.surface,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.colorScheme.surface,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      color: theme.colorScheme.error,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Primary badge
          if (image.isPrimary)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Primary',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Delete button (only for editable mode)
          if (isEditable && onDeleteImage != null)
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => onDeleteImage!(image.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.onError,
                  ),
                ),
              ),
            ),

          // Tap overlay for image viewer
          if (onImageTap != null)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: () => onImageTap!(image),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
