import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/spacing_constants.dart';
import '../../features/chat/providers/chat_thread_providers.dart';
import 'chat_jump_to_bottom_fab.dart';

/// Jump-to-latest control that watches viewport only
/// (CHAT-PERF-002 / CHAT-THREAD-004).
class ChatThreadJumpFabLayer extends ConsumerWidget {
  final int peerUserId;
  final VoidCallback onPressed;

  const ChatThreadJumpFabLayer({
    super.key,
    required this.peerUserId,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewport = ref.watch(chatThreadViewportProvider(peerUserId));
    return Positioned(
      right: AppSpacing.spacingLG,
      bottom: AppSpacing.spacingSM,
      child: ChatJumpToBottomFab(
        visible: viewport.showFab,
        unseenCount: viewport.unseenCount,
        onPressed: onPressed,
      ),
    );
  }
}
