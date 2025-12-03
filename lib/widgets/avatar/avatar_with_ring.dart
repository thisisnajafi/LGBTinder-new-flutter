// Widget: AvatarWithRing
// Avatar with gradient ring
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing_constants.dart';
import '../images/optimized_image.dart';
import 'avatar_with_status.dart';

/// Avatar with gradient ring widget
/// Avatar surrounded by a gradient ring (for premium/featured users)
class AvatarWithRing extends ConsumerWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final double ringWidth;
  final bool isOnline;
  final Gradient? ringGradient;

  const AvatarWithRing({
    Key? key,
    this.imageUrl,
    this.name,
    this.size = 64.0,
    this.ringWidth = 3.0,
    this.isOnline = false,
    this.ringGradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradient = ringGradient ?? AppTheme.accentGradient;

    return Container(
      width: size + (ringWidth * 2),
      height: size + (ringWidth * 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
      padding: EdgeInsets.all(ringWidth),
      child: AvatarWithStatus(
        imageUrl: imageUrl,
        name: name,
        isOnline: isOnline,
        size: size,
      ),
    );
  }
}
