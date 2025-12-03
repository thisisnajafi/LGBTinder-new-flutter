// Widget: ChatListEmpty
// Empty state for chat list
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../error_handling/empty_state.dart';
import '../../core/utils/app_icons.dart';

/// Empty state for chat list widget
/// Shows when user has no chat conversations
class ChatListEmpty extends ConsumerWidget {
  const ChatListEmpty({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmptyState(
      title: 'No conversations yet',
      message: 'Start swiping to find matches and begin chatting!',
      iconPath: AppIcons.chatBubbleOutline,
    );
  }
}
