import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';

/// Short message shown over the top of the Discover card, for example when
/// a swipe could not be sent and the profile was put back.
///
/// Unlike a `SnackBar` it never takes touches and never covers the action
/// bar, so the next swipe is not held up while it is visible. The owner
/// sets [message] and clears it again (null) after a few seconds.
///
/// Usage:
/// ```dart
/// DiscoverSwipeNotice(message: _swipeNotice)
/// ```
class DiscoverSwipeNotice extends StatelessWidget {
  const DiscoverSwipeNotice({super.key, required this.message});

  /// Text to show; null hides the notice.
  final ValueListenable<String?> message;

  /// The visible pill (tests).
  @visibleForTesting
  static const Key pillKey = ValueKey('discover-swipe-notice');

  /// How long the owner should keep a message up.
  static const Duration hold = Duration(seconds: 3);

  @override
  Widget build(BuildContext context) {
    final animate = AppAnimations.animationsEnabled(context);
    return IgnorePointer(
      child: ValueListenableBuilder<String?>(
        valueListenable: message,
        builder: (context, text, _) {
          return AnimatedSwitcher(
            duration: animate ? AppAnimations.snackbarTransition : Duration.zero,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: text == null
                ? const SizedBox.shrink(key: ValueKey('discover-notice-none'))
                : _NoticePill(key: ValueKey(text), text: text),
          );
        },
      ),
    );
  }
}

class _NoticePill extends StatelessWidget {
  const _NoticePill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      container: true,
      label: text,
      child: ExcludeSemantics(
        child: Container(
          key: DiscoverSwipeNotice.pillKey,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.spacingMD,
            vertical: AppSpacing.spacingSM,
          ),
          decoration: BoxDecoration(
            color: scheme.inverseSurface,
            borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSvgIcon(
                assetPath: AppIcons.refresh,
                size: AppSpacing.spacingLG,
                color: scheme.onInverseSurface,
              ),
              const SizedBox(width: AppSpacing.spacingSM),
              Flexible(
                child: AppText(
                  text,
                  maxLines: 3,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
