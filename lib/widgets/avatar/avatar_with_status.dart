// Widget: AvatarWithStatus
// Avatar with online status
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../badges/online_badge.dart';
import '../images/optimized_image.dart';

/// Avatar with online status widget
/// Displays user avatar with online indicator
class AvatarWithStatus extends ConsumerWidget {
  final String? imageUrl;
  final String? name;
  final bool isOnline;
  final double size;
  final bool showRing;
  final Color? ringColor;

  const AvatarWithStatus({
    Key? key,
    this.imageUrl,
    this.name,
    required this.isOnline,
    this.size = 56.0,
    this.showRing = false,
    this.ringColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ring = ringColor ?? AppColors.accentPurple;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: showRing
                ? Border.all(
                    color: ring,
                    width: 2.5,
                  )
                : null,
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? OptimizedImage(
                    imageUrl: imageUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    placeholder: _buildPlaceholder(context, name),
                  )
                : _buildPlaceholder(context, name),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: OnlineBadge(
            isOnline: isOnline,
            size: size * 0.25,
            borderWidth: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context, String? name) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Container(
      color: bgColor,
      child: Center(
        child: name != null && name.isNotEmpty
            ? Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              )
            : Icon(
                Icons.person,
                size: size * 0.6,
                color: textColor,
              ),
      ),
    );
  }
}
