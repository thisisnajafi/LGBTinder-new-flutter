import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../../providers/discovery_provider.dart';

/// Action buttons row widget for discovery
/// Provides like, dislike, superlike, and other action buttons
class ActionButtonsRow extends ConsumerStatefulWidget {
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
  ConsumerState<ActionButtonsRow> createState() => _ActionButtonsRowState();
}

class _ActionButtonsRowState extends ConsumerState<ActionButtonsRow> {
  bool _isSending = false;

  Future<void> _runAction(Future<void> Function() action, String label) async {
    if (_isSending) return;
    setState(() => _isSending = true);
    try {
      await action();
    } catch (e, stack) {
      AppLogger.error(
        '$label failed',
        tag: 'ActionButtonsRow',
        error: e,
        stackTrace: stack,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final discoveryNotifier = ref.read(discoveryProvider.notifier);
    final disabled = _isSending;

    return AnimatedOpacity(
      opacity: disabled ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (widget.showRewind)
              _buildActionButton(
                context: context,
                icon: AppIcons.undo,
                color: Colors.yellow,
                size: 48,
                onPressed: disabled
                    ? null
                    : (widget.onRewind ?? () => discoveryNotifier.rewindProfile()),
                tooltip: 'Rewind',
              ),
            _buildActionButton(
              context: context,
              icon: AppIcons.close,
              color: AppColors.feedbackError,
              size: 56,
              onPressed: disabled
                  ? null
                  : () => _runAction(
                        discoveryNotifier.dislikeCurrentProfile,
                        'Dislike',
                      ),
              tooltip: 'Dislike',
            ),
            _buildActionButton(
              context: context,
              icon: AppIcons.star,
              color: AppColors.primaryLight,
              size: 48,
              onPressed: disabled
                  ? null
                  : () => _runAction(
                        discoveryNotifier.superlikeCurrentProfile,
                        'Superlike',
                      ),
              tooltip: 'Super Like',
            ),
            _buildActionButton(
              context: context,
              icon: AppIcons.heart,
              color: AppColors.feedbackSuccess,
              size: 56,
              onPressed: disabled
                  ? null
                  : () => _runAction(
                        discoveryNotifier.likeCurrentProfile,
                        'Like',
                      ),
              tooltip: 'Like',
            ),
            if (widget.showBoost)
              _buildActionButton(
                context: context,
                icon: AppIcons.lightning,
                color: Colors.purple,
                size: 48,
                onPressed: disabled ? null : widget.onBoost,
                tooltip: 'Boost Profile',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String icon,
    required Color color,
    required double size,
    required VoidCallback? onPressed,
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
