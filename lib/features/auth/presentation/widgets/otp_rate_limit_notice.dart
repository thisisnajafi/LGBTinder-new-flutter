import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../utils/otp_rate_limit.dart';

/// Shows a lockout countdown from [retryAfterSeconds], then a resend action.
class OtpRateLimitNotice extends StatefulWidget {
  const OtpRateLimitNotice({
    super.key,
    required this.retryAfterSeconds,
    required this.onResend,
  });

  final int retryAfterSeconds;
  final Future<bool> Function() onResend;

  @override
  State<OtpRateLimitNotice> createState() => _OtpRateLimitNoticeState();
}

class _OtpRateLimitNoticeState extends State<OtpRateLimitNotice> {
  late int _remaining;
  Timer? _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _start(widget.retryAfterSeconds);
  }

  @override
  void didUpdateWidget(covariant OtpRateLimitNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.retryAfterSeconds != widget.retryAfterSeconds) {
      _start(widget.retryAfterSeconds);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start(int seconds) {
    _timer?.cancel();
    _remaining = seconds < 0 ? 0 : seconds;
    if (_remaining <= 0) return;
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

  Future<void> _handleResend() async {
    if (_remaining > 0 || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.onResend();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final surface = isDark
        ? AppColors.accentPurple.withValues(alpha: 0.18)
        : AppColors.accentPurple.withValues(alpha: 0.10);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentPurple.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            OtpRateLimit.waitMessage(_remaining),
            style: AppTypography.body.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          if (_remaining <= 0) ...[
            SizedBox(height: AppSpacing.spacingSM),
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
        ],
      ),
    );
  }
}
