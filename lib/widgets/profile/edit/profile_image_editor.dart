// Widget: ProfileImageEditor
// Profile image editing
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../profile/avatar_upload.dart';
import '../../images/optimized_image.dart';
import '../../buttons/icon_button_circle.dart';
import '../../../core/utils/app_icons.dart';

/// Profile image editor widget
/// Allows editing and reordering profile images
class ProfileImageEditor extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final Function(String)? onImageAdd;
  final Function(int)? onImageDelete;
  final Function(int, int)? onImageReorder;
  final Function(int)? onImageSetPrimary;

  const ProfileImageEditor({
    Key? key,
    required this.imageUrls,
    this.onImageAdd,
    this.onImageDelete,
    this.onImageReorder,
    this.onImageSetPrimary,
  }) : super(key: key);

  @override
  ConsumerState<ProfileImageEditor> createState() => _ProfileImageEditorState();
}

class _ProfileImageEditorState extends ConsumerState<ProfileImageEditor> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Images',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: widget.imageUrls.length + 1,
            itemBuilder: (context, index) {
              if (index == widget.imageUrls.length) {
                return _buildAddImageButton(context, isDark, surfaceColor, borderColor);
              }
              return _buildImageItem(context, index, widget.imageUrls[index], isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(
    BuildContext context,
    int index,
    String imageUrl,
    bool isDark,
  ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          child: OptimizedImage(
            imageUrl: imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButtonCircle(
            icon: Icons.close,
            onTap: () => widget.onImageDelete?.call(index),
            size: 32.0,
            backgroundColor: Colors.black54,
            iconColor: Colors.white,
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingSM,
                vertical: AppSpacing.spacingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentPurple,
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
              ),
              child: Text(
                'Primary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddImageButton(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    return GestureDetector(
      onTap: () => widget.onImageAdd?.call(''),
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
