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
    this.height = 24,
    this.barCount = 12,
    this.progress = 0,
  });

  @override
  State<VoiceWaveformBars> createState() => _VoiceWaveformBarsState();
}

class _VoiceWaveformBarsState extends State<VoiceWaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final phase = (index / widget.barCount) * math.pi * 2;
              final wave = widget.active
                  ? (0.35 +
                      0.65 *
                          ((math.sin(_controller.value * math.pi * 2 + phase) +
                                  1) /
                              2))
                  : 0.25;
              final isPlayed = index < activeBars;
              final barColor = isPlayed
                  ? widget.color
                  : widget.color.withValues(alpha: 0.35);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 3,
                  height: widget.height * wave,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
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
