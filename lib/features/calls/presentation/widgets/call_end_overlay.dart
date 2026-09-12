import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../data/models/call_end_summary.dart';

/// Fade-to-black + summary card after hang-up. Agora teardown is owned by
/// the page so media stops before this overlay finishes.
class CallEndOverlay extends StatefulWidget {
  final CallEndSummary? summary;
  final VoidCallback onFinished;

  const CallEndOverlay({
    super.key,
    required this.summary,
    required this.onFinished,
  });

  @override
  State<CallEndOverlay> createState() => _CallEndOverlayState();
}

class _CallEndOverlayState extends State<CallEndOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  Timer? _hold;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.callEndFade,
    );
    _curved = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curveDefault,
    );
    if (widget.summary != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _play();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = CallEndSummary.fadeDuration(
      reduceMotion: !AppAnimations.animationsEnabled(context),
    );
  }

  @override
  void didUpdateWidget(CallEndOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.summary != null && oldWidget.summary == null) {
      _play();
    }
  }

  void _play() {
    _hold?.cancel();
    final reduce = !AppAnimations.animationsEnabled(context);
    _controller.duration = CallEndSummary.fadeDuration(reduceMotion: reduce);
    if (reduce) {
      _controller.value = 1;
    } else {
      unawaited(_controller.forward());
    }
    _hold = Timer(
      CallEndSummary.fadeDuration(reduceMotion: reduce) +
          CallEndSummary.holdDuration(reduceMotion: reduce),
      _finish,
    );
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _hold?.cancel();
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    if (summary == null) return const SizedBox.shrink();

    final durationText = summary.durationLabel;
    final negative = summary.reason != CallEndReason.ended;
    final accent = negative
        ? AppColors.feedbackError
        : AppColors.textPrimaryDark;

    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) {
        return AbsorbPointer(
          child: Opacity(
            key: const ValueKey('call-end-fade'),
            opacity: _curved.value,
            child: ColoredBox(
              color: AppColors.backgroundDark,
              child: child,
            ),
          ),
        );
      },
      child: Center(
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(_curved),
          child: Semantics(
            liveRegion: true,
            label: [
              summary.title,
              if (durationText != null) durationText,
            ].join('. '),
            child: Container(
              key: const ValueKey('call-end-card'),
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingXL,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingXL,
                vertical: AppSpacing.spacingXL,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSvgIcon(
                    assetPath:
                        summary.isVideo ? AppIcons.video : AppIcons.call,
                    size: 32,
                    color: accent,
                  ),
                  const SizedBox(height: AppSpacing.spacingMD),
                  Text(
                    summary.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  if (durationText != null) ...[
                    const SizedBox(height: AppSpacing.spacingSM),
                    Text(
                      durationText,
                      key: const ValueKey('call-end-duration'),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimaryDark.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
