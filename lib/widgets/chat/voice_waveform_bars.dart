import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated waveform bars for voice recording and playback.
class VoiceWaveformBars extends StatefulWidget {
  final bool active;
  final Color color;
  final double height;
  final int barCount;
  final double progress;

  const VoiceWaveformBars({
    super.key,
    required this.active,
    required this.color,
    this.height = 28,
    this.barCount = 22,
    this.progress = 0,
  });

  @override
  State<VoiceWaveformBars> createState() => _VoiceWaveformBarsState();
}

class _VoiceWaveformBarsState extends State<VoiceWaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Deterministic idle heights so the waveform looks natural before playback.
  double _idleHeightFactor(int index) {
    final phase = (index / widget.barCount) * math.pi * 2.4;
    final wave = (math.sin(phase) + math.sin(phase * 1.7 + 0.6)) / 2;
    return (0.28 + (wave + 1) * 0.32).clamp(0.22, 0.92);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VoiceWaveformBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress.clamp(0.0, 1.0);
    final activeBars = (widget.barCount * progress).round();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 160.0;
        const gap = 2.4;
        final barWidth = math.max(
          2.2,
          (maxWidth - (widget.barCount - 1) * gap) / widget.barCount,
        );

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return SizedBox(
              height: widget.height,
              width: maxWidth,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(widget.barCount, (index) {
                  final phase = (index / widget.barCount) * math.pi * 2;
                  final idleFactor = _idleHeightFactor(index);
                  final wave = widget.active
                      ? (0.32 +
                          0.68 *
                              ((math.sin(_controller.value * math.pi * 2 + phase) +
                                      1) /
                                  2))
                      : idleFactor;
                  final isPlayed = index < activeBars;
                  final barColor = isPlayed
                      ? widget.color
                      : widget.color.withValues(alpha: widget.active ? 0.42 : 0.34);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    width: barWidth,
                    height: widget.height * wave,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(barWidth),
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }
}

/// Pulsing red dot shown while recording voice.
class PulsingRecordDot extends StatefulWidget {
  final Color color;

  const PulsingRecordDot({super.key, required this.color});

  @override
  State<PulsingRecordDot> createState() => _PulsingRecordDotState();
}

class _PulsingRecordDotState extends State<PulsingRecordDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.85 + (_controller.value * 0.3);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.45),
                  blurRadius: 6 + (_controller.value * 4),
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
