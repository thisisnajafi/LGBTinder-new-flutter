// Widget: ChatListEmpty
// Empty state for chat list
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../error_handling/empty_state.dart';
import '../../core/utils/app_icons.dart';

/// Empty state for chat list widget
/// Shows when user has no chat conversations
class ChatListEmpty extends ConsumerWidget {
  static const String noneTitle = 'No conversations yet';
  static const String noneMessage =
      'Start swiping to find matches and begin chatting!';
  static const String searchTitle = 'No conversations found';
  static const String searchMessage = 'Try a different name or message.';
  static const String discoverLabel = 'Discover People';

  static bool isSearchQuery(String query) => query.trim().isNotEmpty;

  static bool showsDiscoverCta(String query) => !isSearchQuery(query);

  static String titleFor(String query) =>
      isSearchQuery(query) ? searchTitle : noneTitle;

  static String messageFor(String query) =>
      isSearchQuery(query) ? searchMessage : noneMessage;

  final String title;
  final String message;
  final String? iconPath;
  final VoidCallback? onDiscover;

  const ChatListEmpty({
    super.key,
    this.title = noneTitle,
    this.message = noneMessage,
    this.iconPath,
    this.onDiscover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showDiscover = onDiscover != null && title == noneTitle;
    return EmptyState(
      title: title,
      message: message,
      iconPath: iconPath ?? AppIcons.chatBubbleOutline,
      actionLabel: showDiscover ? discoverLabel : null,
      onAction: showDiscover ? onDiscover : null,
    );
  }
}
