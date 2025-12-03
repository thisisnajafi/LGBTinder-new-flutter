// Widget: VerificationBadge
// User verification badge
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// User verification badge widget
/// Displays a verified checkmark icon for verified users
class VerificationBadge extends ConsumerWidget {
  final bool isVerified;
  final double size;
  final Color? backgroundColor;

  const VerificationBadge({
    Key? key,
    required this.isVerified,
    this.size = 20.0,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVerified) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? AppColors.accentPurple;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.verified,
        size: size * 0.7,
        color: Colors.white,
      ),
    );
  }
}
