import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/screenshot_protection.dart';
import '../../../../core/widgets/app_action_bottom_sheet.dart';
import '../../../../features/chat/providers/chat_providers.dart';
import '../../../../features/chat/utils/self_destruct_countdown.dart';
import '../../../../features/chat/utils/self_destruct_send.dart';

/// Full-screen self-destruct photo viewer (CHAT-SD-002 / CHAT-SD-003).
///
/// View-only: no pinch, no share, no download. FLAG_SECURE on Android.
/// Countdown ring is driven by [AnimationController] (not a setState timer).
class SelfDestructViewer extends ConsumerStatefulWidget {
  final int messageId;
  final int? initialRemainingSeconds;
  final int? totalSeconds;

  const SelfDestructViewer({
    super.key,
    required this.messageId,
    this.initialRemainingSeconds,
    this.totalSeconds,
  });

  static Future<bool?> open(
    BuildContext context, {
    required int messageId,
    int? initialRemainingSeconds,
    int? totalSeconds,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (context) => SelfDestructViewer(
          messageId: messageId,
          initialRemainingSeconds: initialRemainingSeconds,
          totalSeconds: totalSeconds,
        ),
      ),
    );
  }

  @override
  ConsumerState<SelfDestructViewer> createState() => _SelfDestructViewerState();
}

class _SelfDestructViewerState extends ConsumerState<SelfDestructViewer>
    with TickerProviderStateMixin {
  String? _imageUrl;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<void>? _screenshotSub;
  bool _consumed = false;
  bool _showDisappearedCopy = false;
  bool _finishing = false;
  bool _popped = false;

  Duration _window = Duration.zero;
  late final AnimationController _fadeController;
  late final AnimationController _countdownController;

  Duration get _totalDuration {
    final seconds = widget.totalSeconds ??
        widget.initialRemainingSeconds ??
        SelfDestructSend.defaultViewSeconds;
    final total = Duration(
      seconds: seconds <= 0 ? SelfDestructSend.defaultViewSeconds : seconds,
    );
    if (_window > Duration.zero && _window > total) return _window;
    return total;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: SelfDestructCountdown.fadeToBlack,
    );
    _countdownController = AnimationController(vsync: this);
    _countdownController.addStatusListener(_onCountdownStatus);
    _enableScreenshotProtection();
    _screenshotSub = ScreenshotProtection.screenshots.listen((_) {
      unawaited(_onScreenshotTaken());
    });
    unawaited(_loadView());
  }

  Future<void> _enableScreenshotProtection() async {
    await ScreenshotProtection.enable();
  }

  Future<void> _onScreenshotTaken() async {
    AppLogger.warning(
      'Self-destruct screenshot; closing viewer',
      tag: 'Chat',
    );
    unawaited(() async {
      try {
        await ref.read(chatServiceProvider).reportScreenshot(widget.messageId);
      } catch (e) {
        AppLogger.warning(
          'Screenshot report failed for ${widget.messageId}',
          tag: 'Chat',
          error: e,
        );
      }
    }());
    _popConsumed();
  }

  Future<void> _disableScreenshotProtection() async {
    await ScreenshotProtection.disable();
  }

  Future<void> _loadView() async {
    try {
      final payload = await ref
          .read(chatServiceProvider)
          .viewSelfDestructMessage(widget.messageId);

      if (!mounted) return;

      final remaining = SelfDestructCountdown.remainingFromPayload(
        expiresAtIso: payload['expires_at']?.toString(),
        remainingSeconds: int.tryParse(
              payload['remaining_seconds']?.toString() ?? '',
            ) ??
            widget.initialRemainingSeconds ??
            widget.totalSeconds,
      );

      setState(() {
        _imageUrl = payload['secure_media_url']?.toString();
        _window = remaining;
        _isLoading = false;
        _consumed = _imageUrl != null && _imageUrl!.isNotEmpty;
      });

      _startCountdown();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Self-destruct view failed for message ${widget.messageId}',
        tag: 'Chat',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _error = 'Unable to open photo';
        _isLoading = false;
        _consumed = false;
      });
    }
  }

  void _onCountdownStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      unawaited(_finishExpired());
    }
  }

  void _startCountdown() {
    _countdownController.stop();
    if (_window <= Duration.zero) {
      unawaited(_finishExpired());
      return;
    }
    _countdownController.duration = _window;
    _countdownController.forward(from: 0);
  }

  Future<void> _finishExpired() async {
    if (_finishing) return;
    _finishing = true;
    _countdownController.stop();
    if (!mounted) return;

    final animate = AppAnimations.animationsEnabled(context);
    _fadeController.duration =
        animate ? SelfDestructCountdown.fadeToBlack : Duration.zero;
    await _fadeController.forward();
    if (!mounted) return;
    setState(() => _showDisappearedCopy = true);
    if (animate) {
      await Future<void>.delayed(SelfDestructCountdown.disappearedHold);
    }
    _popConsumed();
  }

  void _popConsumed() {
    if (!mounted || _popped) return;
    _popped = true;
    Navigator.of(context).pop(_consumed);
  }

  @override
  void dispose() {
    _screenshotSub?.cancel();
    _countdownController.removeStatusListener(_onCountdownStatus);
    _countdownController.dispose();
    _fadeController.dispose();
    unawaited(_disableScreenshotProtection());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _popConsumed();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Close',
            onPressed: _popConsumed,
            icon: AppSvgIcon(
              assetPath: AppIcons.close,
              size: 24,
              color: AppColors.textPrimaryDark,
            ),
          ),
          actions: [
            if (!_showDisappearedCopy)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.spacingMD),
                child: Center(
                  child: _CountdownBadge(
                    controller: _countdownController,
                    total: _totalDuration,
                    textTheme: textTheme,
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildBody(),
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                if (_fadeController.value <= 0 && !_showDisappearedCopy) {
                  return const SizedBox.shrink();
                }
                return Opacity(
                  opacity: _fadeController.value.clamp(0.0, 1.0),
                  child: child,
                );
              },
              child: ColoredBox(
                color: AppColors.backgroundDark,
                child: Center(
                  child: _showDisappearedCopy
                      ? Text(
                          SelfDestructCountdown.disappearedCopy,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimaryDark,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }

    if (_error != null || _imageUrl == null) {
      return Center(
        child: Padding(
          padding: ResponsivePadding.page(context),
          child: AppText(
            _error ?? 'Photo unavailable',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ),
      );
    }

    // View-only: InteractiveViewer with pinch/pan disabled (CHAT-SD-002).
    return ColoredBox(
      color: AppColors.backgroundDark,
      child: InteractiveViewer(
        panEnabled: false,
        scaleEnabled: false,
        minScale: 1,
        maxScale: 1,
        child: Center(
          child: Image.network(
            _imageUrl!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              AppLogger.warning(
                'Self-destruct image failed to decode',
                tag: 'Chat',
                error: error,
              );
              return AppText(
                'Photo unavailable',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({
    required this.controller,
    required this.total,
    required this.textTheme,
  });

  final AnimationController controller;
  final Duration total;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final duration = controller.duration ?? total;
        final remainingMs =
            (duration.inMilliseconds * (1 - controller.value)).round();
        final remaining =
            Duration(milliseconds: remainingMs < 0 ? 0 : remainingMs);
        final displaySeconds = SelfDestructCountdown.displaySeconds(remaining);
        if (displaySeconds <= 0) return const SizedBox.shrink();
        final progress = SelfDestructCountdown.ringProgress(
          remaining: remaining,
          total: total,
        );
        return SizedBox(
          width: 44,
          height: 44,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _CountdownRingPainter(
                progress: progress,
                color: SelfDestructCountdown.drainColor(progress),
                trackColor: AppColors.textPrimaryDark.withValues(alpha: 0.24),
              ),
              child: Center(
                child: Text(
                  '$displaySeconds',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _CountdownRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 3.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2,
      6.283185307179586 * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

/// Duration picker for self-destruct photos (5 / 10 / 30 / 60 second pills).
class SelfDestructDurationSheet extends StatelessWidget {
  const SelfDestructDurationSheet({super.key});

  static Future<int?> show(BuildContext context) {
    return AppActionBottomSheet.show<int>(
      context: context,
      showCancel: true,
      body: const SelfDestructDurationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = SelfDestructSend.durationOptionsSeconds;

    return AppBottomSheetCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spacingLG,
          AppSpacing.spacingLG,
          AppSpacing.spacingLG,
          AppSpacing.spacingXL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Self-destruct photo',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.spacingXS),
            Text(
              'How long can they view it?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: AppSpacing.spacingLG),
            Wrap(
              spacing: AppSpacing.spacingSM,
              runSpacing: AppSpacing.spacingSM,
              children: [
                for (final seconds in options)
                  _DurationPill(
                    seconds: seconds,
                    onTap: () => Navigator.pop(context, seconds),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationPill extends StatelessWidget {
  final int seconds;
  final VoidCallback onTap;

  const _DurationPill({required this.seconds, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = SelfDestructSend.formatDuration(seconds);

    return Semantics(
      button: true,
      label: '$seconds seconds',
      child: Material(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingLG,
              ),
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
