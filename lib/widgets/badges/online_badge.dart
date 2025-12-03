// Widget: OnlineBadge
// Online status badge
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';

/// Online status badge widget
/// Displays a green dot indicator for online users
class OnlineBadge extends ConsumerWidget {
  final bool isOnline;
  final double size;
  final double borderWidth;

  const OnlineBadge({
    Key? key,
    required this.isOnline,
    this.size = 12.0,
    this.borderWidth = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.onlineGreen,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onlineGreen.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
