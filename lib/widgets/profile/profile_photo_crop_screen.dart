import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/app_media_picker.dart';
import '../../core/utils/image_upload_compressor.dart';
import '../../core/utils/profile_photo_crop_encoder.dart';
import '../../core/utils/square_crop_geometry.dart';
import '../buttons/gradient_button.dart';
import '../buttons/scale_tap_feedback.dart';

/// Full-screen 1:1 crop step shown after picking a profile photo.
class ProfilePhotoCropScreen extends StatefulWidget {
  const ProfilePhotoCropScreen({
    super.key,
    required this.imageFile,
  });

  final File imageFile;

  static const titleKey = ValueKey<String>('profile-photo-crop-title');
  static const confirmKey = ValueKey<String>('profile-photo-crop-confirm');
  static const cancelKey = ValueKey<String>('profile-photo-crop-cancel');

  static Future<File?> open(BuildContext context, File imageFile) {
    return Navigator.of(context).push<File>(
      PageRouteBuilder<File>(
        transitionDuration: AppAnimations.pageTransitionDuration(context),
        reverseTransitionDuration: AppAnimations.pageTransitionDuration(context),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ProfilePhotoCropScreen(imageFile: imageFile);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (!AppAnimations.animationsEnabled(context)) return child;
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: AppAnimations.curveDefault,
            ),
            child: child,
          );
        },
      ),
    );
  }

  /// Compresses [file] then opens the 1:1 crop step. Null if cancelled.
  static Future<File?> cropFile(BuildContext context, File file) async {
    final prepared = await ImageUploadCompressor.prepareForPreview(file);
    if (!context.mounted) return null;
    return open(context, prepared);
  }

  /// Camera/gallery pick followed by a required square crop.
  static Future<File?> pickAndCrop(
    BuildContext context, {
    required ImageSource source,
  }) async {
    final picked = await AppMediaPicker.pickImage(source: source);
    if (picked == null || !context.mounted) return null;
    return cropFile(context, File(picked.path));
  }

  @override
  State<ProfilePhotoCropScreen> createState() => _ProfilePhotoCropScreenState();
}

class _ProfilePhotoCropScreenState extends State<ProfilePhotoCropScreen> {
  Size? _imageSize;
  Uint8List? _bytes;
  Object? _loadError;
  double _scale = SquareCropGeometry.minScale;
  Offset _pan = Offset.zero;
  int _quarterTurns = 0;
  Size _viewport = const Size(100, 100);
  Offset _panAtScaleStart = Offset.zero;
  double _scaleAtStart = SquareCropGeometry.minScale;
  bool _saving = false;

  SquareCropGeometry get _geometry {
    final imageSize = _imageSize;
    if (imageSize == null) {
      return SquareCropGeometry(
        imageSize: Size.zero,
        viewportSize: _viewport,
        scale: _scale,
        pan: _pan,
        quarterTurns: _quarterTurns,
      );
    }
    return SquareCropGeometry(
      imageSize: imageSize,
      viewportSize: _viewport,
      scale: _scale,
      pan: _pan,
      quarterTurns: _quarterTurns,
    ).clamped();
  }

  @override
  void initState() {
    super.initState();
    _loadSize();
  }

  Future<void> _loadSize() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _imageSize = size;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _panAtScaleStart = _geometry.clampedPan;
    _scaleAtStart = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_imageSize == null) return;
    setState(() {
      _scale = (_scaleAtStart * details.scale).clamp(
        SquareCropGeometry.minScale,
        SquareCropGeometry.maxScale,
      );
      _pan = _panAtScaleStart + details.focalPointDelta;
    });
  }

  void _rotate() {
    AppHaptics.selection();
    setState(() {
      _quarterTurns += 1;
      _pan = Offset.zero;
    });
  }

  void _reset() {
    AppHaptics.light();
    setState(() {
      _scale = SquareCropGeometry.minScale;
      _pan = Offset.zero;
      _quarterTurns = 0;
    });
  }

  Future<void> _confirm() async {
    if (_saving || _imageSize == null) return;
    setState(() => _saving = true);
    AppHaptics.medium();
    try {
      final cropped = await ProfilePhotoCropEncoder.encodeSquare(
        source: widget.imageFile,
        geometry: _geometry.clamped(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(cropped);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not crop photo: $error'),
          backgroundColor: AppColors.feedbackError,
        ),
      );
    }
  }

  void _cancel() {
    if (_saving) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spacingSM,
                AppSpacing.spacingSM,
                AppSpacing.spacingSM,
                0,
              ),
              child: Row(
                children: [
                  _CircleIconButton(
                    key: ProfilePhotoCropScreen.cancelKey,
                    assetPath: AppIcons.close,
                    semanticLabel: 'Cancel crop',
                    onTap: _saving ? null : _cancel,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        AppText(
                          'Crop photo',
                          key: ProfilePhotoCropScreen.titleKey,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                        const SizedBox(height: AppSpacing.spacingXS),
                        AppText(
                          'Square 1:1 for your profile',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: onSurface.withValues(alpha: 0.55),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48, height: 48),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.contentPadding),
                child: _buildStage(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.contentPadding,
                0,
                AppSpacing.contentPadding,
                AppSpacing.spacingLG,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CircleIconButton(
                        assetPath: AppIcons.refreshOutline,
                        semanticLabel: 'Reset crop',
                        onTap: _saving ? null : _reset,
                      ),
                      const SizedBox(width: AppSpacing.spacingXL),
                      _CircleIconButton(
                        assetPath: AppIcons.rotateRight,
                        semanticLabel: 'Rotate photo',
                        onTap: _saving ? null : _rotate,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacingSM),
                  AppText(
                    'Pinch to zoom · drag to reposition',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withValues(alpha: 0.55),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                  const SizedBox(height: AppSpacing.spacingLG),
                  GradientButton(
                    key: ProfilePhotoCropScreen.confirmKey,
                    text: 'Use photo',
                    iconPath: AppIcons.check,
                    isLoading: _saving,
                    onPressed: (_imageSize == null || _loadError != null)
                        ? null
                        : _confirm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage(BuildContext context) {
    if (_loadError != null) {
      return Center(
        child: AppText(
          'Could not open this photo',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_imageSize == null || _bytes == null) {
      return Center(
        child: AppSvgIcon(
          assetPath: AppIcons.crop,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        _viewport = Size(side, side);
        final geometry = _geometry;
        final display = geometry.displayedSize;
        final origin = geometry.imageOrigin;

        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.radiusSM),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: Theme.of(context).colorScheme.surface),
                  GestureDetector(
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    child: Stack(
                      children: [
                        Positioned(
                          left: origin.dx,
                          top: origin.dy,
                          width: display.width,
                          height: display.height,
                          child: RotatedBox(
                            quarterTurns: geometry.normalizedTurns,
                            child: Image.memory(
                              _bytes!,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.medium,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _CropFramePainter(
                        borderGradient: AppTheme.accentGradient,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    super.key,
    required this.assetPath,
    required this.semanticLabel,
    this.onTap,
  });

  final String assetPath;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surfaceElevatedLight;
    final iconColor = theme.colorScheme.onSurface;

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onTap != null,
      child: ScaleTapFeedback(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.borderSubtleDark
                      : AppColors.borderSubtleLight,
                ),
              ),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: AppSvgIcon(
                    assetPath: assetPath,
                    size: 22,
                    color: iconColor,
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

class _CropFramePainter extends CustomPainter {
  const _CropFramePainter({
    required this.borderGradient,
  });

  final Gradient borderGradient;

  @override
  void paint(Canvas canvas, Size size) {
    final borderRect = Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3);
    final borderRRect = RRect.fromRectAndRadius(
      borderRect,
      Radius.circular(AppRadius.radiusSM - 1),
    );
    final borderPaint = Paint()
      ..shader = borderGradient.createShader(borderRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(borderRRect, borderPaint);

    final handlePaint = Paint()
      ..shader = borderGradient.createShader(Offset.zero & size)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const handle = AppSpacing.spacingLG;
    final inset = AppSpacing.spacingSM + 2;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(
      Offset(inset, inset + handle),
      Offset(inset, inset),
      handlePaint,
    );
    canvas.drawLine(
      Offset(inset, inset),
      Offset(inset + handle, inset),
      handlePaint,
    );
    canvas.drawLine(
      Offset(w - inset - handle, inset),
      Offset(w - inset, inset),
      handlePaint,
    );
    canvas.drawLine(
      Offset(w - inset, inset),
      Offset(w - inset, inset + handle),
      handlePaint,
    );
    canvas.drawLine(
      Offset(inset, h - inset - handle),
      Offset(inset, h - inset),
      handlePaint,
    );
    canvas.drawLine(
      Offset(inset, h - inset),
      Offset(inset + handle, h - inset),
      handlePaint,
    );
    canvas.drawLine(
      Offset(w - inset - handle, h - inset),
      Offset(w - inset, h - inset),
      handlePaint,
    );
    canvas.drawLine(
      Offset(w - inset, h - inset - handle),
      Offset(w - inset, h - inset),
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CropFramePainter oldDelegate) {
    return false;
  }
}
