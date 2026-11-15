import 'package:flutter/material.dart';

import '../../../core/theme/spacing_constants.dart';
import '../../../widgets/discovery/discovery_swipe_action_button.dart';

/// The four Discover actions under the card: rewind, pass, super like, like.
///
/// Pass and like are the primary actions and are larger than rewind and
/// super like. On narrow screens or with large text the row scales down as
/// a whole instead of overflowing; every button keeps a 48 dp tap area.
///
/// Usage:
/// ```dart
/// DiscoverActionBar(
///   onRewind: _rewind,
///   onPass: () => _swipe('dislike'),
///   onSuperlike: _superlike,
///   onLike: () => _swipe('like'),
///   rewindLocked: !plan.features.rewind,
/// )
/// ```
class DiscoverActionBar extends StatelessWidget {
  const DiscoverActionBar({
    super.key,
    required this.onRewind,
    required this.onPass,
    required this.onSuperlike,
    required this.onLike,
    this.rewindLocked = false,
  });

  /// Null disables the button. With [rewindLocked] it should open the
  /// upgrade screen.
  final VoidCallback? onRewind;
  final VoidCallback? onPass;
  final VoidCallback? onSuperlike;
  final VoidCallback? onLike;

  /// Rewind needs a higher plan: the button shows a lock badge.
  final bool rewindLocked;

  /// Visual diameter of pass and like.
  static const double primarySize = 64;

  /// Visual diameter of super like.
  static const double secondarySize = 52;

  /// Visual diameter of rewind.
  static const double tertiarySize = 48;

  /// Height the bar needs at its natural size.
  static const double height = primarySize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Discover actions',
      child: SizedBox(
        height: height,
        // Scale the whole row down on very narrow screens instead of
        // overflowing or scrolling. Layout runs once, not per frame.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DiscoverySwipeActionButton(
                type: DiscoverySwipeActionType.rewind,
                size: tertiarySize,
                locked: rewindLocked,
                onPressed: onRewind,
              ),
              const SizedBox(width: AppSpacing.spacingLG),
              DiscoverySwipeActionButton(
                type: DiscoverySwipeActionType.dislike,
                size: primarySize,
                onPressed: onPass,
              ),
              const SizedBox(width: AppSpacing.spacingLG),
              DiscoverySwipeActionButton(
                type: DiscoverySwipeActionType.superlike,
                size: secondarySize,
                onPressed: onSuperlike,
              ),
              const SizedBox(width: AppSpacing.spacingLG),
              DiscoverySwipeActionButton(
                type: DiscoverySwipeActionType.like,
                size: primarySize,
                onPressed: onLike,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
