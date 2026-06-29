// Widget: ProfileImageEditor
// Profile image editing
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../images/optimized_image.dart';
import '../../buttons/icon_button_circle.dart';
import '../../../core/utils/app_icons.dart';

/// Profile image editor widget
/// Allows editing, reordering, and setting the primary profile image.
class ProfileImageEditor extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final int primaryIndex;
  final Function(String)? onImageAdd;
  final Function(int)? onImageDelete;
  final Function(int, int)? onImageReorder;
  final Function(int)? onImageSetPrimary;
  final int? maxImages;
  final bool galleryOnly;

  const ProfileImageEditor({
    Key? key,
    required this.imageUrls,
    this.primaryIndex = 0,
    this.maxImages,
    this.galleryOnly = false,
    this.onImageAdd,
    this.onImageDelete,
    this.onImageReorder,
    this.onImageSetPrimary,
  }) : super(key: key);

  @override
  ConsumerState<ProfileImageEditor> createState() => _ProfileImageEditorState();
}

class _ProfileImageEditorState extends ConsumerState<ProfileImageEditor> {
  int? _draggingIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final canAddMore = widget.maxImages == null ||
        widget.imageUrls.length < widget.maxImages!;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.galleryOnly ? 'Images' : 'Profile Images',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          if (!widget.galleryOnly && widget.imageUrls.length > 1) ...[
            SizedBox(height: AppSpacing.spacingXS),
            Text(
              'Hold and drag to reorder. Tap a photo to set it as primary.',
              style: theme.textTheme.bodySmall?.copyWith(color: secondaryTextColor),
            ),
          ],
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
            itemCount: widget.imageUrls.length + (canAddMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (canAddMore && index == widget.imageUrls.length) {
                return _buildAddImageButton(context, isDark, surfaceColor, borderColor);
              }
              return _buildDraggableImageItem(context, index, isDark, borderColor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableImageItem(
    BuildContext context,
    int index,
    bool isDark,
    Color borderColor,
  ) {
    final imageUrl = widget.imageUrls[index];
    final isPrimary =
        !widget.galleryOnly && index == widget.primaryIndex;
    final canReorder = widget.onImageReorder != null && widget.imageUrls.length > 1;

    Widget tile = _buildImageTile(
      context: context,
      index: index,
      imageUrl: imageUrl,
      isPrimary: isPrimary,
      isDragging: _draggingIndex == index,
      borderColor: borderColor,
    );

    if (!canReorder) {
      return tile;
    }

    return LongPressDraggable<int>(
      data: index,
      delay: const Duration(milliseconds: 150),
      onDragStarted: () => setState(() => _draggingIndex = index),
      onDragEnd: (_) => setState(() => _draggingIndex = null),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 100,
          height: 133,
          child: _buildImageTile(
            context: context,
            index: index,
            imageUrl: imageUrl,
            isPrimary: isPrimary,
            isDragging: false,
            borderColor: borderColor,
            elevated: true,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != index,
        onAcceptWithDetails: (details) {
          widget.onImageReorder?.call(details.data, index);
        },
        builder: (context, candidateData, rejectedData) {
          final isDropTarget = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: isDropTarget
                  ? Border.all(color: AppColors.accentPurple, width: 2)
                  : null,
            ),
            child: tile,
          );
        },
      ),
    );
  }

  Widget _buildImageTile({
    required BuildContext context,
    required int index,
    required String imageUrl,
    required bool isPrimary,
    required bool isDragging,
    required Color borderColor,
    bool elevated = false,
  }) {
    return Semantics(
      label: isPrimary ? 'Primary profile photo' : 'Profile photo ${index + 1}',
      button: !isPrimary && widget.onImageSetPrimary != null,
      child: GestureDetector(
        onTap: !isPrimary && widget.onImageSetPrimary != null
            ? () => widget.onImageSetPrimary?.call(index)
            : null,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isPrimary
                        ? AppColors.accentPurple
                        : (isDragging ? AppColors.accentPurple : borderColor),
                    width: isPrimary ? 2 : 1,
                  ),
                  boxShadow: elevated
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: OptimizedImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButtonCircle(
                svgIcon: AppIcons.close,
                onTap: () => widget.onImageDelete?.call(index),
                size: 32.0,
                backgroundColor: Colors.black54,
                iconColor: Colors.white,
                semanticLabel: 'Remove photo',
              ),
            ),
            if (isPrimary)
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
                  child: const Text(
                    'Primary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else if (!widget.galleryOnly && widget.onImageSetPrimary != null)
              Positioned(
                bottom: 4,
                left: 4,
                child: IconButtonCircle(
                  svgIcon: AppIcons.star,
                  onTap: () => widget.onImageSetPrimary?.call(index),
                  size: 28.0,
                  backgroundColor: Colors.black54,
                  iconColor: Colors.white,
                  semanticLabel: 'Set as primary photo',
                ),
              ),
          ],
        ),
      ),
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
            const Text(
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
