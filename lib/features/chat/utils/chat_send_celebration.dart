import 'package:flutter/material.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../presentation/widgets/chat_send_celebration_burst.dart';

/// Detects sticker / single-emoji sends and plays a short burst (CHAT-ANIM-004).
class ChatSendCelebration {
  ChatSendCelebration._();

  /// Send-button origin shared by text send and the sticker picker.
  static final GlobalKey sendOriginKey = GlobalKey(debugLabel: 'chatSendOrigin');

  static bool shouldCelebrateText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final runes = trimmed.runes.toList();
    var clusters = 0;
    var i = 0;
    while (i < runes.length) {
      final cp = runes[i];
      if (_isJoiner(cp) || _isSkinTone(cp)) {
        i++;
        continue;
      }
      if (!_isPictographic(cp)) return false;
      clusters++;
      i++;
      while (i < runes.length) {
        final next = runes[i];
        if (_isJoiner(next) || _isSkinTone(next)) {
          i++;
          continue;
        }
        if (i > 0 && _isJoiner(runes[i - 1]) && _isPictographic(next)) {
          i++;
          continue;
        }
        break;
      }
    }
    return clusters == 1;
  }

  static bool shouldCelebrate({
    required String text,
    String? messageType,
  }) {
    final type = messageType?.toLowerCase();
    if (type == 'sticker') return true;
    return shouldCelebrateText(text);
  }

  static bool _isJoiner(int codePoint) =>
      codePoint == 0x200D || codePoint == 0xFE0F || codePoint == 0xFE0E;

  static bool _isSkinTone(int codePoint) =>
      codePoint >= 0x1F3FB && codePoint <= 0x1F3FF;

  static bool _isPictographic(int codePoint) {
    if (codePoint >= 0x1F300 && codePoint <= 0x1FAFF) return true;
    if (codePoint >= 0x1F1E6 && codePoint <= 0x1F1FF) return true;
    if (codePoint >= 0x2600 && codePoint <= 0x27BF) return true;
    if (codePoint >= 0x2300 && codePoint <= 0x23FF) return true;
    if (codePoint >= 0x2B50 && codePoint <= 0x2B55) return true;
    return false;
  }

  static void tryPlay({
    required BuildContext context,
    required String text,
    String? messageType,
  }) {
    if (!shouldCelebrate(text: text, messageType: messageType)) return;
    play(context);
  }

  static void play(BuildContext context) {
    if (!context.mounted) return;
    if (!AppAnimations.animationsEnabled(context)) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final center = _originCenter() ?? _fallbackCenter(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return ChatSendCelebrationBurst(
          globalCenter: center,
          colors: AppColors.lgbtGradient,
          onDone: () {
            if (entry.mounted) entry.remove();
          },
        );
      },
    );
    overlay.insert(entry);
  }

  static Offset? _originCenter() {
    final box = sendOriginKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  static Offset _fallbackCenter(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    return Offset(
      size.width - padding.right - AppAnimations.chatEmojiCelebrationTravel,
      size.height - padding.bottom - AppAnimations.chatEmojiCelebrationTravel,
    );
  }
}
