import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_date_time.dart';

/// Telegram-style date pill pinned under the chat header
/// (CHAT-THREAD-005). Inline timeline slots stay for grouping math only.
class ChatDateBadge extends StatelessWidget {
  const ChatDateBadge({
    super.key,
    required this.label,
  });

  final String label;

  static Color backgroundOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? AppColors.surfaceElevatedDark.withValues(alpha: 0.88)
        : AppColors.surfaceElevatedLight;
  }

  static Color foregroundOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  }

  static Color borderOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.borderSubtleDark : AppColors.borderSubtleLight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      header: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingMD,
                vertical: AppSpacing.spacingXS,
              ),
              decoration: BoxDecoration(
                color: backgroundOf(context),
                borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                border: Border.all(color: borderOf(context)),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.28 : 0.10,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foregroundOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inserts `{kind: date_badge}` rows before the first item of each calendar day.
class ChatDateBadgeInserter {
  ChatDateBadgeInserter._();

  static const String kind = 'date_badge';

  static List<Map<String, dynamic>> wrap(
    List<Map<String, dynamic>> items, {
    DateTime? now,
  }) {
    final out = <Map<String, dynamic>>[];
    DateTime? lastDay;

    for (final item in items) {
      final ts = _timestamp(item);
      if (ts != null) {
        final day = DateTime(ts.year, ts.month, ts.day);
        if (lastDay == null || day != lastDay) {
          out.add({
            'kind': kind,
            'label': AppDateTime.formatChatDateBadge(ts, now: now),
            'timestamp': day,
          });
          lastDay = day;
        }
      }
      out.add(item);
    }

    return out;
  }

  static DateTime? _timestamp(Map<String, dynamic> item) {
    final raw = item['timestamp'];
    if (raw is DateTime) return AppDateTime.toLocal(raw);
    return AppDateTime.parseApi(raw);
  }
}
