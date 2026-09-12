import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../shared/services/agora_rtc_types.dart';
import '../../data/models/call_signal_bars.dart';
import '../../providers/agora_rtc_session_provider.dart';

/// Four-bar Agora quality indicator. Watches [networkQualityProvider] only.
class CallNetworkSignal extends ConsumerWidget {
  const CallNetworkSignal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quality = ref.watch(networkQualityProvider);
    final animate = AppAnimations.animationsEnabled(context);
    final filled = CallSignalBars.filledCount(quality);
    final color = _colorFor(quality);
    final duration = animate ? AppAnimations.callSignalBar : Duration.zero;
    final empty = color.withValues(alpha: 0.24);

    return Semantics(
      label: 'Network quality $quality',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < CallSignalBars.barCount; i++) ...[
            if (i > 0) SizedBox(width: AppSpacing.spacingXS / 2),
            AnimatedContainer(
              duration: duration,
              curve: AppAnimations.curveDefault,
              width: AppSpacing.spacingXS,
              height: AppSpacing.spacingSM + i * AppSpacing.spacingXS,
              decoration: BoxDecoration(
                color: i < filled ? color : empty,
                borderRadius: BorderRadius.circular(AppSpacing.spacingXS / 2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _colorFor(String quality) {
    switch (quality) {
      case AgoraNetworkQuality.excellent:
      case AgoraNetworkQuality.good:
        return AppColors.feedbackSuccess;
      case AgoraNetworkQuality.poor:
        return AppColors.feedbackWarning;
      case AgoraNetworkQuality.bad:
        return AppColors.feedbackError;
      default:
        return AppColors.textSecondaryDark;
    }
  }
}
