// Widget: EmptyState
// Empty state widget — optional fade in on appear
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/constants/animation_constants.dart';
import '../buttons/gradient_button.dart';
import '../../core/utils/app_icons.dart';

/// Empty state widget
/// Displays a message when there's no content to show; fades in over ~300 ms
class EmptyState extends ConsumerStatefulWidget {
  final String title;
  final String? message;
  final IconData? icon; // Legacy support
  final String? iconPath; // SVG icon path
  final String? actionLabel;
  final VoidCallback? onAction;
  /// When true, show a thin gradient line below the title (subtle pride accent).
  final bool showPrideAccent;

  const EmptyState({
    Key? key,
    required this.title,
    this.message,
    this.icon,
    this.iconPath,
    this.actionLabel,
    this.onAction,
    this.showPrideAccent = true,
  }) : super(key: key);

  @override
  ConsumerState<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends ConsumerState<EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.curveDefault),
    );
    // Start after first frame so context is valid and we don't block build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppAnimations.animationsEnabled(context)) {
        _controller.forward();
      } else {
        _controller.value = 1;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final content = Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.iconPath != null || widget.icon != null) ...[
              widget.iconPath != null
                  ? AppSvgIcon(
                      assetPath: widget.iconPath!,
                      size: 64,
                      color: secondaryTextColor.withValues(alpha: 0.5),
                    )
                  : Icon(
                      widget.icon!,
                      size: 64,
                      color: secondaryTextColor.withValues(alpha: 0.5),
                    ),
              SizedBox(height: AppSpacing.spacingXL),
            ],
            Text(
              widget.title,
              style: AppTypography.h3.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            if (widget.showPrideAccent) ...[
              SizedBox(height: AppSpacing.spacingMD),
              Container(
                width: 48,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: AppColors.lgbtGradient.map((c) => c.withOpacity(0.6)).toList(),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
            if (widget.message != null) ...[
              SizedBox(height: AppSpacing.spacingMD),
              Text(
                widget.message!,
                style: AppTypography.body.copyWith(color: secondaryTextColor),
                textAlign: TextAlign.center,
              ),
            ],
            if (widget.actionLabel != null && widget.onAction != null) ...[
              SizedBox(height: AppSpacing.spacingXXL),
              GradientButton(
                text: widget.actionLabel!,
                onPressed: widget.onAction,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );

    return FadeTransition(
      opacity: _fade,
      child: content,
    );
  }
}
