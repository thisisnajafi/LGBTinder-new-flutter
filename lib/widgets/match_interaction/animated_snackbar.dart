// Widget: AnimatedSnackbar
// Animated snackbar notifications — slide up + fade using AppAnimations.snackbarTransition
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/utils/app_icons.dart';

/// Animated snackbar widget
/// Custom snackbar with slide-in animation and gradient background
class AnimatedSnackbar extends ConsumerWidget {
  final String message;
  final SnackbarType type;
  final Duration duration;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AnimatedSnackbar({
    super.key,
    required this.message,
    this.type = SnackbarType.info,
    this.duration = const Duration(seconds: 3),
    this.onAction,
    this.actionLabel,
  });

  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final overlay = Overlay.of(context);
    final animate = AppAnimations.animationsEnabled(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _SnackbarOverlay(
        entry: entry,
        displayDuration: duration,
        animate: animate,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AnimatedSnackbar(
                message: message,
                type: type,
                duration: duration,
                onAction: onAction,
                actionLabel: actionLabel,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const textColor = Colors.white;

    Color getBackgroundColor() {
      switch (type) {
        case SnackbarType.success:
          return AppColors.onlineGreen;
        case SnackbarType.error:
          return AppColors.notificationRed;
        case SnackbarType.warning:
          return AppColors.warningYellow;
        case SnackbarType.info:
          return AppColors.accentPurple;
      }
    }

    String getIconPath() {
      switch (type) {
        case SnackbarType.success:
          return AppIcons.checkCircle;
        case SnackbarType.error:
          return AppIcons.danger;
        case SnackbarType.warning:
          return AppIcons.warning;
        case SnackbarType.info:
          return AppIcons.infoCircle;
      }
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        gradient: type == SnackbarType.info
            ? AppTheme.accentGradient
            : LinearGradient(
                colors: [
                  getBackgroundColor(),
                  getBackgroundColor().withValues(alpha: 0.8),
                ],
              ),
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AppSvgIcon(
            assetPath: getIconPath(),
            color: textColor,
            size: AppSpacing.spacingXL,
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: AppText(
              message,
              style: AppTypography.body.copyWith(color: textColor),
              maxLines: 3,
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            SizedBox(width: AppSpacing.spacingMD),
            TextButton(
              onPressed: onAction,
              child: AppText(
                actionLabel!,
                style: AppTypography.button.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum SnackbarType {
  success,
  error,
  warning,
  info,
}

class _SnackbarOverlay extends StatefulWidget {
  final OverlayEntry entry;
  final Duration displayDuration;
  final bool animate;
  final Widget child;

  const _SnackbarOverlay({
    required this.entry,
    required this.displayDuration,
    required this.animate,
    required this.child,
  });

  @override
  State<_SnackbarOverlay> createState() => _SnackbarOverlayState();
}

class _SnackbarOverlayState extends State<_SnackbarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.snackbarTransition,
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.curveDefault),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.curveDefault),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.entry.remove();
      }
    });
    // Start after first frame so context is valid and we don't block build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.animate) {
        _controller.value = 1;
        _holdTimer = Timer(widget.displayDuration, () {
          if (mounted) widget.entry.remove();
        });
        return;
      }
      _controller.forward();
      _holdTimer = Timer(widget.displayDuration, () {
        if (mounted) _controller.reverse();
      });
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bar = widget.animate
        ? SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: widget.child,
            ),
          )
        : widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: bar,
        ),
      ],
    );
  }
}
