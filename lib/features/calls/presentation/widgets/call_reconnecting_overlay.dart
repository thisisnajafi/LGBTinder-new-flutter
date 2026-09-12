import 'package:flutter/material.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';

/// Dim overlay while Agora is reconnecting or the remote peer has dropped.
class CallReconnectingOverlay extends StatefulWidget {
  final bool visible;
  final String message;

  const CallReconnectingOverlay({
    super.key,
    required this.visible,
    this.message = 'Reconnecting…',
  });

  @override
  State<CallReconnectingOverlay> createState() => _CallReconnectingOverlayState();
}

class _CallReconnectingOverlayState extends State<CallReconnectingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: AppAnimations.shimmerDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSpin();
  }

  @override
  void didUpdateWidget(CallReconnectingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSpin();
  }

  void _syncSpin() {
    final animate =
        widget.visible && AppAnimations.animationsEnabled(context);
    if (animate) {
      if (!_spin.isAnimating) {
        _spin.repeat();
      }
    } else if (_spin.isAnimating) {
      _spin.stop();
      _spin.value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = AppAnimations.animationsEnabled(context);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: animate ? AppAnimations.feedbackShort : Duration.zero,
        curve: AppAnimations.curveDefault,
        child: widget.visible
            ? ColoredBox(
                color: AppColors.backgroundDark.withValues(alpha: 0.55),
                child: Center(
                  child: Semantics(
                    liveRegion: true,
                    label: widget.message,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacingXL,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacingXL,
                        vertical: AppSpacing.spacingLG,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppSvgIcon(
                            assetPath: AppIcons.wifi,
                            size: 28,
                            color: AppColors.feedbackWarning,
                          ),
                          const SizedBox(height: AppSpacing.spacingSM),
                          RotationTransition(
                            turns: _spin,
                            child: AppSvgIcon(
                              assetPath: AppIcons.refresh,
                              size: 20,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spacingSM),
                          Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
