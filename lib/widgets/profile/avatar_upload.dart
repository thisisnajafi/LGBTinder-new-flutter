// Widget: AvatarUpload
// Avatar upload widget
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../images/optimized_image.dart';
import '../buttons/icon_button_circle.dart';
import '../../core/utils/app_icons.dart';

/// Avatar upload widget
/// Displays avatar with upload/edit button overlay
class AvatarUpload extends ConsumerStatefulWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final Function()? onUpload;
  final Function()? onEdit;
  final Function()? onSetPrimary;
  final bool showEditButton;
  final bool showPrimaryBadge;

  const AvatarUpload({
    Key? key,
    this.imageUrl,
    this.name,
    this.size = 120.0,
    this.onUpload,
    this.onEdit,
    this.onSetPrimary,
    this.showEditButton = true,
    this.showPrimaryBadge = false,
  }) : super(key: key);

  @override
  ConsumerState<AvatarUpload> createState() => _AvatarUploadState();
}

class _AvatarUploadState extends ConsumerState<AvatarUpload> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final placeholderColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: placeholderColor,
            border: Border.all(
              color: isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                ? (widget.imageUrl!.startsWith('http') || widget.imageUrl!.startsWith('https')
                    ? OptimizedImage(
                        imageUrl: widget.imageUrl!,
                        width: widget.size,
                        height: widget.size,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(widget.imageUrl!),
                        width: widget.size,
                        height: widget.size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: placeholderColor,
                            child: Icon(
                              Icons.person,
                              size: widget.size * 0.4,
                              color: textColor,
                            ),
                          );
                        },
                      ))
                : Container(
                    color: placeholderColor,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            size: widget.size * 0.4,
                            color: textColor,
                          ),
                          if (widget.name != null && widget.name!.isNotEmpty) ...[
                            SizedBox(height: AppSpacing.spacingXS),
                            Text(
                              widget.name![0].toUpperCase(),
                              style: TextStyle(
                                fontSize: widget.size * 0.3,
                                color: textColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        if (widget.showPrimaryBadge &&
            widget.imageUrl != null &&
            widget.imageUrl!.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
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
          ),
        if (widget.onSetPrimary != null &&
            widget.imageUrl != null &&
            widget.imageUrl!.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            child: IconButtonCircle(
              svgIcon: AppIcons.star,
              onTap: widget.onSetPrimary,
              size: 32.0,
              backgroundColor: AppColors.accentPurple,
              iconColor: Colors.white,
              semanticLabel: 'Set as primary photo',
            ),
          ),
        if (widget.showEditButton)
          Positioned(
            bottom: 0,
            right: 0,
            child: IconButtonCircle(
              svgIcon: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                  ? AppIcons.edit
                  : AppIcons.galleryAdd,
              onTap: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                  ? widget.onEdit
                  : widget.onUpload,
              size: 32.0,
              backgroundColor: AppColors.accentPurple,
              iconColor: Colors.white,
              semanticLabel: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                  ? 'Change primary photo'
                  : 'Add primary photo',
            ),
          ),
      ],
    );
  }
}
