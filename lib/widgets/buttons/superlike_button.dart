// Widget: SuperlikeButton
// Superlike action button
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Superlike action button widget
/// Star-shaped button with gradient for superliking profiles
class SuperlikeButton extends ConsumerStatefulWidget {
  final VoidCallback? onTap;
  final bool isActive;
  final double size;

  const SuperlikeButton({
    Key? key,
    this.onTap,
    this.isActive = false,
    this.size = 64.0,
  }) : super(key: key);

  @override
  ConsumerState<SuperlikeButton> createState() => _SuperlikeButtonState();
}

class _SuperlikeButtonState extends ConsumerState<SuperlikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: widget.isActive
                ? AppTheme.accentGradient
                : LinearGradient(
                    colors: [
                      AppColors.warningYellow.withOpacity(0.3),
                      AppColors.warningYellow.withOpacity(0.3),
                    ],
                  ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.warningYellow.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.star,
            color: widget.isActive ? Colors.white : AppColors.warningYellow,
            size: widget.size * 0.4,
          ),
        ),
      ),
    );
  }
}
