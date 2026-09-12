import '../../../core/theme/spacing_constants.dart';

/// Pure implicit-reorder math for messenger rows (CHAT-MSG-001).
class ChatListReorder {
  ChatListReorder._();

  /// Avatar (52) + vertical padding (SM×2) + [ListView] separator (XS).
  static const double rowStride =
      52 + AppSpacing.spacingSM * 2 + AppSpacing.spacingXS;

  /// First hydrate and no-ops must not animate.
  static bool shouldAnimate({
    required int previousIndex,
    required int index,
  }) {
    if (previousIndex == index) return false;
    if (previousIndex < 0) return index == 0;
    return true;
  }

  /// Pixel [dy] from the previous slot toward the laid-out slot (then 0).
  ///
  /// A brand-new top row uses virtual index `-1` so it slides in from above.
  static double slidePixels({
    required int previousIndex,
    required int index,
  }) {
    final from = previousIndex < 0 ? -1 : previousIndex;
    return (from - index) * rowStride;
  }
}
