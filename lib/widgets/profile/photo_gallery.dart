// Widget: PhotoGallery
// Profile photo gallery
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../images/optimized_image.dart';
import '../../core/utils/app_icons.dart';

/// Profile photo gallery widget
/// Displays user's profile and gallery images in a grid
/// Data structure based on API: user.profile_images, user.gallery_images
class PhotoGallery extends ConsumerWidget {
  final List<String> imageUrls;
  final Function(int, String)? onImageTap;
  final bool isEditable;
  final VoidCallback? onAddPhoto;
  final int crossAxisCount;

  const PhotoGallery({
    Key? key,
    required this.imageUrls,
    this.onImageTap,
    this.isEditable = false,
    this.onAddPhoto,
    this.crossAxisCount = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    if (imageUrls.isEmpty && !isEditable) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photos',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppSpacing.spacingSM,
              mainAxisSpacing: AppSpacing.spacingSM,
              childAspectRatio: 0.75,
            ),
            itemCount: imageUrls.length + (isEditable && onAddPhoto != null ? 1 : 0),
            itemBuilder: (context, index) {
              if (isEditable && onAddPhoto != null && index == imageUrls.length) {
                return _buildAddPhotoButton(context, isDark, surfaceColor, borderColor);
              }
              return _buildPhotoItem(context, index, imageUrls[index], isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(BuildContext context, int index, String imageUrl, bool isDark) {
    return GestureDetector(
      onTap: () => onImageTap?.call(index, imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: OptimizedImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    return GestureDetector(
      onTap: onAddPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(
              assetPath: AppIcons.galleryAdd,
              size: 32,
              color: AppColors.accentPurple,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            Text(
              'Add Photo',
              style: TextStyle(
                color: AppColors.accentPurple,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
