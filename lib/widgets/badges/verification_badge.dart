// Widget: VerificationBadge
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_icons.dart';

class VerificationBadge extends ConsumerWidget {
  final bool isVerified;
  final double size;

  const VerificationBadge({
    super.key,
    required this.isVerified,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVerified) return const SizedBox.shrink();

    return Semantics(
      label: 'Verified profile',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.accentPurple,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPurple.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: AppSvgIcon(
            assetPath: AppIcons.getIconPath('verify', style: 'bold'),
            size: size * 0.65,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
    );
  }
}
