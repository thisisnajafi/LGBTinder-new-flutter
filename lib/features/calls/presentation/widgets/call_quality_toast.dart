import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../providers/agora_rtc_session_provider.dart';
import '../../utils/call_quality_toast_gate.dart';

/// Auto-hiding toast for Agora quality 4–5. Bars stay in the header (CALL-UI-007).
class CallQualityToast extends ConsumerStatefulWidget {
  const CallQualityToast({super.key});

  @override
  ConsumerState<CallQualityToast> createState() => _CallQualityToastState();
}

class _CallQualityToastState extends ConsumerState<CallQualityToast>
    with SingleTickerProviderStateMixin {
  final CallQualityToastGate _gate = CallQualityToastGate(
    debounce: AppAnimations.callQualityToastDebounce,
  );
  late final Ticker _holdTicker;
  bool _visible = false;
  ProviderSubscription<String>? _qualitySub;
  ProviderSubscription<bool>? _reconnectSub;

  @override
  void initState() {
    super.initState();
    _holdTicker = createTicker((elapsed) {
      if (elapsed >= AppAnimations.callQualityToastHold) {
        _dismiss();
      }
    });
    _qualitySub = ref.listenManual<String>(networkQualityProvider, (_, next) {
      _sync(
        quality: next,
        reconnecting: ref.read(agoraRtcSessionProvider).isReconnecting,
      );
    });
    _reconnectSub = ref.listenManual<bool>(
      agoraRtcSessionProvider.select((state) => state.isReconnecting),
      (_, reconnecting) {
        _sync(
          quality: ref.read(networkQualityProvider),
          reconnecting: reconnecting,
        );
      },
    );
  }

  @override
  void dispose() {
    _qualitySub?.close();
    _reconnectSub?.close();
    _holdTicker.dispose();
    super.dispose();
  }

  void _sync({required String quality, required bool reconnecting}) {
    if (reconnecting) {
      _dismiss();
      return;
    }
    if (!_gate.take(quality: quality, now: DateTime.now())) return;
    _show();
  }

  void _show() {
    if (!_visible) {
      setState(() => _visible = true);
    }
    if (!_holdTicker.isTicking) {
      _holdTicker.start();
    }
  }

  void _dismiss() {
    if (_holdTicker.isTicking) {
      _holdTicker.stop();
    }
    if (_visible && mounted) {
      setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = AppAnimations.animationsEnabled(context)
        ? AppAnimations.snackbarTransition
        : Duration.zero;
    final onWarning = AppColors.textPrimaryDark;

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _visible
          ? Center(
              key: const ValueKey('call-quality-toast'),
              child: Semantics(
                liveRegion: true,
                label: 'Poor connection',
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                    vertical: AppSpacing.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.feedbackWarning.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSvgIcon(
                        assetPath: AppIcons.warning,
                        size: 16,
                        color: onWarning,
                      ),
                      SizedBox(width: AppSpacing.spacingXS),
                      Text(
                        'Poor connection',
                        style: AppTypography.labelSmall.copyWith(
                          color: onWarning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('call-quality-toast-hidden')),
    );
  }
}
