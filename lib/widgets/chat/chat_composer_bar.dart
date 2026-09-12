import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/providers/chat_providers.dart';
import '../../features/chat/providers/chat_thread_providers.dart';
import '../../features/chat/utils/chat_message_sheet_actions.dart';
import 'message_input.dart';
import 'message_reply_widget.dart';

/// Reply/edit strip + [MessageInput] (CHAT-PERF-007).
class ChatComposerBar extends ConsumerWidget {
  final int peerUserId;
  final Function(String) onSend;
  final VoidCallback onMediaTap;
  final VoidCallback onMediaLongPress;
  final Future<bool> Function() onVoiceRecordStart;
  final Future<void> Function() onVoiceRecordSend;
  final Future<void> Function() onVoiceRecordCancel;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<bool> onFocusChange;

  const ChatComposerBar({
    super.key,
    required this.peerUserId,
    required this.onSend,
    required this.onMediaTap,
    required this.onMediaLongPress,
    required this.onVoiceRecordStart,
    required this.onVoiceRecordSend,
    required this.onVoiceRecordCancel,
    required this.onTextChanged,
    required this.onFocusChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composer = ref.watch(chatComposerProvider(peerUserId));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MessageReplyWidget(
          isEditing: composer.isEditing,
          repliedToName: composer.isEditing
              ? ChatMessageSheetActions.editingBarTitle(
                  createdAt: composer.editingCreatedAt,
                )
              : composer.replyName,
          repliedToMessage:
              composer.isEditing ? composer.editingPreview : composer.replyText,
          repliedToMessageType:
              composer.isEditing ? 'text' : composer.replyType,
          onCancel: () {
            ref.read(chatComposerProvider(peerUserId).notifier).clear();
            ref.read(pendingChatDraftProvider.notifier).state = null;
          },
        ),
        MessageInput(
          peerUserId: peerUserId,
          onSend: onSend,
          celebrateSend: !composer.isEditing,
          isEditing: composer.isEditing,
          onMediaTap: onMediaTap,
          onMediaLongPress: onMediaLongPress,
          onVoiceRecordStart: onVoiceRecordStart,
          onVoiceRecordSend: onVoiceRecordSend,
          onVoiceRecordCancel: onVoiceRecordCancel,
          hintText:
              composer.isEditing ? 'Edit message...' : 'Type a message...',
          onTextChanged: onTextChanged,
          onFocusChange: onFocusChange,
        ),
      ],
    );
  }
}
