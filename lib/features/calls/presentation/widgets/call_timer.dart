import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/call_provider.dart';

/// Call timer widget
/// Displays and manages call duration
class CallTimer extends ConsumerStatefulWidget {
  final bool isActive;
  final TextStyle? textStyle;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;

  const CallTimer({
    Key? key,
    this.isActive = true,
    this.textStyle,
    this.textColor,
    this.fontSize,
    this.fontWeight,
  }) : super(key: key);

  @override
  ConsumerState<CallTimer> createState() => _CallTimerState();
}

class _CallTimerState extends ConsumerState<CallTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(CallTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startTimer();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final callNotifier = ref.read(callProvider.notifier);
        final currentDuration = ref.read(callProvider).callDuration;
        callNotifier.updateCallDuration(currentDuration + const Duration(seconds: 1));
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callProvider);
    final duration = callState.callDuration;

    final textStyle = widget.textStyle ??
        TextStyle(
          color: widget.textColor ?? Theme.of(context).colorScheme.onSurface,
          fontSize: widget.fontSize ?? 16,
          fontWeight: widget.fontWeight ?? FontWeight.w500,
        );

    return Text(
      _formatDuration(duration),
      style: textStyle,
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
  }
}

/// Call timer with label
class CallTimerWithLabel extends ConsumerWidget {
  final String label;
  final bool isActive;
  final TextStyle? labelStyle;
  final TextStyle? timerStyle;
  final MainAxisAlignment alignment;

  const CallTimerWithLabel({
    Key? key,
    required this.label,
    this.isActive = true,
    this.labelStyle,
    this.timerStyle,
    this.alignment = MainAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: labelStyle ??
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),

        const SizedBox(height: 4),

        CallTimer(
          isActive: isActive,
          textStyle: timerStyle ??
              Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}

/// Compact call timer (for status bars)
class CompactCallTimer extends ConsumerWidget {
  final bool isActive;
  final Color? color;
  final double fontSize;

  const CompactCallTimer({
    Key? key,
    this.isActive = true,
    this.color,
    this.fontSize = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callProvider);
    final duration = callState.callDuration;

    return Text(
      _formatDuration(duration),
      style: TextStyle(
        color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        fontFeatures: [const FontFeature.tabularFigures()], // Monospace numbers
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Call timer overlay (for full screen calls)
class CallTimerOverlay extends ConsumerWidget {
  final bool isActive;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;

  const CallTimerOverlay({
    Key? key,
    this.isActive = true,
    this.alignment = Alignment.topCenter,
    this.padding = const EdgeInsets.all(20),
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: CallTimer(
            isActive: isActive,
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Call timer with icon
class CallTimerWithIcon extends ConsumerWidget {
  final bool isActive;
  final IconData icon;
  final Color? iconColor;
  final double iconSize;
  final TextStyle? textStyle;
  final MainAxisAlignment alignment;

  const CallTimerWithIcon({
    Key? key,
    this.isActive = true,
    this.icon = Icons.access_time,
    this.iconColor,
    this.iconSize = 16,
    this.textStyle,
    this.alignment = MainAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          size: iconSize,
        ),

        const SizedBox(width: 6),

        CallTimer(
          isActive: isActive,
          textStyle: textStyle ??
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}

/// Auto-pausing call timer (pauses when app is in background)
class AutoPausingCallTimer extends ConsumerStatefulWidget {
  final TextStyle? textStyle;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;

  const AutoPausingCallTimer({
    Key? key,
    this.textStyle,
    this.textColor,
    this.fontSize,
    this.fontWeight,
  }) : super(key: key);

  @override
  ConsumerState<AutoPausingCallTimer> createState() => _AutoPausingCallTimerState();
}

class _AutoPausingCallTimerState extends ConsumerState<AutoPausingCallTimer>
    with WidgetsBindingObserver {
  bool _isInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isInForeground = state == AppLifecycleState.resumed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallTimer(
      isActive: _isInForeground,
      textStyle: widget.textStyle,
      textColor: widget.textColor,
      fontSize: widget.fontSize,
      fontWeight: widget.fontWeight,
    );
  }
}

/// Call duration formatter utility
class CallDurationFormatter {
  static String format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
  }

  static String formatCompact(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatLong(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours hour${hours == 1 ? '' : 's'} $minutes minute${minutes == 1 ? '' : 's'}';
    } else if (minutes > 0) {
      return '$minutes minute${minutes == 1 ? '' : 's'} $seconds second${seconds == 1 ? '' : 's'}';
    } else {
      return '$seconds second${seconds == 1 ? '' : 's'}';
    }
  }
}