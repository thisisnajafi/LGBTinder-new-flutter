// Widget: AvatarUpload
// Circular profile photo picker with gradient ring and overlay actions.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../images/optimized_image.dart';

/// Avatar upload widget with gradient ring, SVG icons, and half-outside action button.
class AvatarUpload extends ConsumerStatefulWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final VoidCallback? onUpload;
  final VoidCallback? onEdit;
  final VoidCallback? onSetPrimary;
  final bool showEditButton;
  final bool showPrimaryBadge;

  const AvatarUpload({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 120.0,
    this.onUpload,
    this.onEdit,
    this.onSetPrimary,
    this.showEditButton = true,
    this.showPrimaryBadge = false,
  });

  @override
  ConsumerState<AvatarUpload> createState() => _AvatarUploadState();
}

class _AvatarUploadState extends ConsumerState<AvatarUpload> {
  static const double _actionTapSize = 44.0;
  static const double _actionVisualSize = 36.0;

  bool get _hasImage =>
      widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

  VoidCallback? get _primaryAction =>
      _hasImage ? widget.onEdit : widget.onUpload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surfaceContainerHighest;
    final overflow = _actionTapSize / 2;

    return SizedBox(
      width: widget.size + overflow,
      height: widget.size + overflow,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Semantics(
            label: _hasImage ? 'Profile photo' : 'Add profile photo',
            button: !_hasImage,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: !_hasImage ? _primaryAction : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: _hasImage
                      ? _photoAvatar(context, primary)
                      : _emptyAvatar(context, surface, onSurface, primary),
                ),
              ),
            ),
          ),
          if (widget.showPrimaryBadge && _hasImage)
            Positioned(
              top: overflow - 2,
              left: overflow - 2,
              child: _primaryBadge(context, primary),
            ),
          if (widget.onSetPrimary != null && _hasImage)
            Positioned(
              left: overflow - _actionTapSize / 2,
              bottom: overflow - _actionTapSize / 2,
              child: _starButton(context, primary),
            ),
          if (widget.showEditButton)
            Positioned(
              right: 0,
              bottom: 0,
              child: _actionButton(context, primary),
            ),
        ],
      ),
    );
  }

  Widget _photoAvatar(BuildContext context, Color primary) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primary, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(child: _imageContent(context)),
    );
  }

  Widget _emptyAvatar(
    BuildContext context,
    Color surface,
    Color onSurface,
    Color primary,
  ) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.accentGradient,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: surface,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(
                assetPath: AppIcons.userOutline,
                size: widget.size * 0.28,
                color: onSurface.withValues(alpha: 0.38),
              ),
              const SizedBox(height: AppSpacing.spacingXS),
              Text(
                'Tap to add',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageContent(BuildContext context) {
    final url = widget.imageUrl!;
    final placeholder = Theme.of(context).colorScheme.surfaceContainerHighest;

    if (url.startsWith('http')) {
      return OptimizedImage(
        imageUrl: url,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
      );
    }

    return Image.file(
      File(url),
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imageErrorPlaceholder(context, placeholder),
    );
  }

  Widget _imageErrorPlaceholder(BuildContext context, Color placeholder) {
    return Container(
      color: placeholder,
      child: Center(
        child: AppSvgIcon(
          assetPath: AppIcons.userOutline,
          size: widget.size * 0.28,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _primaryBadge(BuildContext context, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingSM,
        vertical: AppSpacing.spacingXS,
      ),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'Primary',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _starButton(BuildContext context, Color primary) {
    return Semantics(
      label: 'Set as primary photo',
      button: true,
      child: Material(
        color: primary,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onSetPrimary,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: _actionVisualSize,
            height: _actionVisualSize,
            child: Center(
              child: AppSvgIcon(
                assetPath: AppIcons.star,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, Color primary) {
    final icon = _hasImage ? AppIcons.camera : AppIcons.galleryAdd;
    final label =
        _hasImage ? 'Change profile photo' : 'Add profile photo';

    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: primary,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _primaryAction,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: _actionTapSize,
            height: _actionTapSize,
            child: Center(
              child: Container(
                width: _actionVisualSize,
                height: _actionVisualSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: icon,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
