// Widget: EmojiPickerWidget
// Emoji picker for messages
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../modals/bottom_sheet_custom.dart';

/// Emoji picker widget
/// Simple emoji picker for chat messages
class EmojiPickerWidget extends ConsumerStatefulWidget {
  final Function(String)? onEmojiSelected;

  const EmojiPickerWidget({
    Key? key,
    this.onEmojiSelected,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    Function(String)? onEmojiSelected,
  }) {
    BottomSheetCustom.show(
      context: context,
      child: EmojiPickerWidget(onEmojiSelected: onEmojiSelected),
    );
  }

  @override
  ConsumerState<EmojiPickerWidget> createState() => _EmojiPickerWidgetState();
}

class _EmojiPickerWidgetState extends ConsumerState<EmojiPickerWidget> {
  // Common emojis for chat
  final List<String> _emojis = [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣',
    '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰',
    '😘', '😗', '😙', '😚', '😋', '😛', '😜', '🤪',
    '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨',
    '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥',
    '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕',
    '🤢', '🤮', '🤧', '🥵', '🥶', '😶‍🌫️', '😵', '😵‍💫',
    '🤯', '🤠', '🥳', '😎', '🤓', '🧐', '😕', '😟',
    '🙁', '☹️', '😮', '😯', '😲', '😳', '🥺', '😦',
    '😧', '😨', '😰', '😥', '😢', '😭', '😱', '😖',
    '😣', '😞', '😓', '😩', '😫', '🥱', '😤', '😡',
    '😠', '🤬', '😈', '👿', '💀', '☠️', '💋', '💌',
    '💘', '💝', '💖', '💗', '💓', '💞', '💕', '💟',
    '❣️', '💔', '❤️', '🧡', '💛', '💚', '💙', '💜',
    '🤎', '🖤', '🤍', '💯', '💢', '💥', '💫', '💦',
    '💨', '🕳️', '💣', '💬', '👁️‍🗨️', '🗨️', '🗯️', '💭',
    '💤', '👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤌',
    '🤏', '✌️', '🤞', '🤟', '🤘', '🤙', '👈', '👉',
    '👆', '🖕', '👇', '☝️', '👍', '👎', '✊', '👊',
    '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝', '🙏',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      height: 300,
      color: surfaceColor,
      child: Column(
        children: [
          // Category tabs (simplified - just show all)
          Container(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
            child: Text(
              'Emoji',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark
                ? AppColors.borderMediumDark
                : AppColors.borderMediumLight,
          ),
          // Emoji grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    widget.onEmojiSelected?.call(_emojis[index]);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    ),
                    child: Center(
                      child: Text(
                        _emojis[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
