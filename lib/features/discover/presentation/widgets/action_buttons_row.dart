import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../../providers/discovery_provider.dart';

/// Action buttons row widget for discovery
/// Provides like, dislike, superlike, and other action buttons
class ActionButtonsRow extends ConsumerWidget {
  final bool showRewind;
  final bool showBoost;
  final VoidCallback? onRewind;
  final VoidCallback? onBoost;

  const ActionButtonsRow({
    Key? key,
    this.showRewind = true,
    this.showBoost = false,
    this.onRewind,
    this.onBoost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryNotifier = ref.read(discoveryProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Rewind button
          if (showRewind)
            _buildActionButton(
              context: context,
              icon: AppIcons.undo,
              color: Colors.yellow,
              size: 48,
              onPressed: onRewind ?? () => discoveryNotifier.rewindProfile(),
              tooltip: 'Rewind',
            ),

          // Dislike button
          _buildActionButton(
            context: context,
            icon: AppIcons.close,
            color: AppColors.feedbackError,
            size: 56,
            onPressed: () => discoveryNotifier.dislikeCurrentProfile(),
            tooltip: 'Dislike',
          ),

          // Superlike button
          _buildActionButton(
            context: context,
            icon: AppIcons.star,
            color: AppColors.primaryLight,
            size: 48,
            onPressed: () => discoveryNotifier.superlikeCurrentProfile(),
            tooltip: 'Super Like',
          ),

          // Like button
          _buildActionButton(
            context: context,
            icon: AppIcons.heart,
            color: AppColors.feedbackSuccess,
            size: 56,
            onPressed: () => discoveryNotifier.likeCurrentProfile(),
            tooltip: 'Like',
          ),

          // Boost button
          if (showBoost)
            _buildActionButton(
              context: context,
              icon: AppIcons.lightning,
              color: Colors.purple,
              size: 48,
              onPressed: onBoost,
              tooltip: 'Boost Profile',
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String icon,
    required Color color,
    required double size,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size + 16,
        height: size + 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            minimumSize: Size(size, size),
            elevation: 4,
            shadowColor: color.withOpacity(0.4),
          ),
          child: AppSvgIcon(
            assetPath: icon,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
