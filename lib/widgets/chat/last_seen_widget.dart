// Widget: LastSeenWidget
// Last seen timestamp widget
import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../features/chat/utils/chat_presence_copy.dart';
import '../../features/chat/utils/presence_freshness.dart';

/// Last seen timestamp widget
/// Displays when a user was last seen online, or "is typing"
class LastSeenWidget extends StatefulWidget {
  final DateTime? lastSeenAt;
  final bool isOnline;
  final bool isTyping;

  /// When the last online heartbeat / presence event was applied.
  /// Online labels older than [PresenceFreshness.ttl] become Last seen.
  final DateTime? presenceRefreshedAt;

  /// Test clock. Production uses [DateTime.now].
  final DateTime Function()? clock;

  const LastSeenWidget({
    super.key,
    this.lastSeenAt,
    this.isOnline = false,
    this.isTyping = false,
    this.presenceRefreshedAt,
    this.clock,
  });

  @override
  State<LastSeenWidget> createState() => _LastSeenWidgetState();
}

class _LastSeenWidgetState extends State<LastSeenWidget> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(LastSeenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  bool get _effectivelyOnline => PresenceFreshness.isEffectivelyOnline(
        isOnline: widget.isOnline,
        refreshedAt: widget.presenceRefreshedAt ?? widget.lastSeenAt,
        now: _now,
      );

  void _syncTicker() {
    if (widget.isTyping || !_effectivelyOnline) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_effectivelyOnline) {
        _ticker?.cancel();
        _ticker = null;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    if (widget.isTyping) {
      return AppText(
        ChatPresenceCopy.isTyping,
        key: const ValueKey('peer-status-typing'),
        style: AppTypography.caption.copyWith(
          color: theme.colorScheme.primary,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
      );
    }

    if (_effectivelyOnline) {
      return Row(
        key: const ValueKey('peer-status-online'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.onlineGreen,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppSpacing.spacingXS),
          AppText(
            ChatPresenceCopy.online,
            style: AppTypography.caption.copyWith(color: textColor),
            maxLines: 1,
          ),
        ],
      );
    }

    final seen = widget.lastSeenAt ?? widget.presenceRefreshedAt;
    if (seen == null) {
      return AppText(
        ChatPresenceCopy.offline,
        key: const ValueKey('peer-status-offline'),
        style: AppTypography.caption.copyWith(color: textColor),
        maxLines: 1,
      );
    }

    return AppText(
      ChatPresenceCopy.lastSeenLabel(seen, now: _now),
      key: const ValueKey('peer-status-last-seen'),
      style: AppTypography.caption.copyWith(color: textColor),
      maxLines: 1,
    );
  }
}
