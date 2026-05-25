import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/providers/chat_typing_providers.dart';
import 'typing_indicator.dart';

/// Typing dots for one chat peer — isolated rebuild (PERF-PAGE-CHAT-005).
class ChatPeerTypingIndicator extends ConsumerWidget {
  final int peerUserId;
  final String? displayName;

  const ChatPeerTypingIndicator({
    super.key,
    required this.peerUserId,
    this.displayName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTyping = ref.watch(isUserTypingProvider(peerUserId));
    if (!isTyping) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TypingIndicator(displayName: displayName),
      ),
    );
  }
}
