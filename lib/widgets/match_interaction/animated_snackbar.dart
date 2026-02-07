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

/// Animated snackbar widget
/// Custom snackbar with slide-in animation and gradient background
class AnimatedSnackbar extends ConsumerWidget {
  final String message;
  final SnackbarType type;
  final Duration duration;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AnimatedSnackbar({
    Key? key,
    required this.message,
    this.type = SnackbarType.info,
    this.duration = const Duration(seconds: 3),
    this.onAction,
    this.actionLabel,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _SnackbarOverlay(
        entry: entry,
        displayDuration: duration,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
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
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = Colors.white;

    Color getBackgroundColor() {
      switch (type) {
        case SnackbarType.success:
          return AppColors.onlineGreen;
        case SnackbarType.error:
          return AppColors.notificationRed;
        case SnackbarType.warning:
          return AppColors.warningYellow;
        case SnackbarType.info:
        default:
          return AppColors.accentPurple;
      }
    }

    IconData getIcon() {
      switch (type) {
        case SnackbarType.success:
          return Icons.check_circle;
        case SnackbarType.error:
          return Icons.error;
        case SnackbarType.warning:
          return Icons.warning;
        case SnackbarType.info:
        default:
          return Icons.info;
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
                  getBackgroundColor().withOpacity(0.8),
                ],
              ),
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            getIcon(),
            color: textColor,
            size: 24,
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(color: textColor),
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            SizedBox(width: AppSpacing.spacingMD),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: AppTypography.button.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
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
  final Widget child;

  const _SnackbarOverlay({
    required this.entry,
    required this.displayDuration,
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
    return Stack(
      children: [
        Positioned.fill(child: const SizedBox.expand()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
