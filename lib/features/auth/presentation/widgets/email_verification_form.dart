import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';

/// Six OTP boxes. Focus chrome stays inside [AnimatedBuilder] so parent
/// rebuilds (verify loading) do not recreate the fields.
class EmailOtpFields extends StatelessWidget {
  const EmailOtpFields({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;

  static const int fieldCount = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.spacingSM;
        final fieldWidth =
            ((constraints.maxWidth - gap * (fieldCount - 1)) / fieldCount)
                .clamp(40.0, 56.0);
        final fieldHeight = (fieldWidth * 1.2).clamp(52.0, 60.0);

        return Row(
          children: [
            for (var index = 0; index < fieldCount; index++) ...[
              if (index > 0) const SizedBox(width: gap),
              Expanded(
                child: _EmailOtpBox(
                  controller: controllers[index],
                  focusNode: focusNodes[index],
                  textColor: textColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  height: fieldHeight,
                  onChanged: (value) => onChanged(index, value),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _EmailOtpBox extends StatelessWidget {
  const _EmailOtpBox({
    required this.controller,
    required this.focusNode,
    required this.textColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.height,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Color textColor;
  final Color surfaceColor;
  final Color borderColor;
  final double height;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            border: Border.all(
              color: focusNode.hasFocus ? AppColors.accentPurple : borderColor,
              width: focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: child,
        );
      },
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTypography.h1.copyWith(color: textColor),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Resend control with its own countdown ticker (PERF-SCR-EMAIL-001).
///
/// Ticks do not [setState] the verification screen. Extra taps are ignored
/// while a request is in flight and for [tapDebounce] after the last tap.
class EmailResendRow extends StatefulWidget {
  const EmailResendRow({
    super.key,
    required this.onResend,
    this.cooldown = const Duration(seconds: 120),
    this.tapDebounce = AppAnimations.searchDebounce,
  });

  /// Return `true` to restart [cooldown].
  final Future<bool> Function() onResend;
  final Duration cooldown;
  final Duration tapDebounce;

  @override
  State<EmailResendRow> createState() => _EmailResendRowState();
}

class _EmailResendRowState extends State<EmailResendRow> {
  late int _remaining;
  Timer? _timer;
  DateTime? _lastTap;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _remaining = widget.cooldown.inSeconds;
    if (_remaining <= 0) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
        return;
      }
      setState(() => _remaining--);
    });
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _handleResend() async {
    if (_remaining > 0 || _busy) return;
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < widget.tapDebounce) {
      return;
    }
    _lastTap = now;
    setState(() => _busy = true);
    try {
      final restart = await widget.onResend();
      if (restart && mounted) {
        setState(_startCountdown);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Didn't receive the code? ",
          style: AppTypography.body.copyWith(color: secondaryTextColor),
        ),
        if (_remaining > 0)
          Text(
            'Resend in ${_formatCountdown(_remaining)}',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
          )
        else
          TextButton(
            onPressed: _busy ? null : _handleResend,
            child: Text(
              _busy ? 'Sending...' : 'Resend Code',
              style: AppTypography.button.copyWith(
                color: AppColors.accentPurple,
              ),
            ),
          ),
      ],
    );
  }
}
