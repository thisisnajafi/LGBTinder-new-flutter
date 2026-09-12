import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../core/services/app_logger.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_action_bottom_sheet.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../features/chat/data/models/chat_forward_result.dart';
import '../../features/chat/utils/chat_forward_attribution.dart';
import '../../features/chat/providers/chat_list_preview_provider.dart';
import '../../features/chat/providers/chat_providers.dart';

/// Conversation picker for forwarding a message (CHAT-THREAD-008).
class ChatForwardSheet {
  ChatForwardSheet._();

  static Future<ChatForwardResult?> show({
    required BuildContext context,
    required int messageId,
  }) {
    return showModalBottomSheet<ChatForwardResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AppBottomSheetShell(
        showCancel: true,
        body: _ChatForwardPicker(messageId: messageId),
      ),
    );
  }
}

class _ChatForwardPicker extends ConsumerStatefulWidget {
  final int messageId;

  const _ChatForwardPicker({required this.messageId});

  @override
  ConsumerState<_ChatForwardPicker> createState() => _ChatForwardPickerState();
}

class _ChatForwardPickerState extends ConsumerState<_ChatForwardPicker> {
  final Set<int> _selected = <int>{};
  final TextEditingController _search = TextEditingController();
  bool _sending = false;
  bool _loadingList = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_ensureChats());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _ensureChats() async {
    final preview = ref.read(chatListPreviewProvider);
    if (preview.isSeeded && preview.items.isNotEmpty) return;
    setState(() => _loadingList = true);
    try {
      final chats =
          await ref.read(chatServiceProvider).getChatUsers(forceRefresh: true);
      if (!mounted) return;
      ref.read(chatListPreviewProvider.notifier).seedFromChats(chats);
    } catch (e) {
      AppLogger.warning(
        'Forward sheet failed to load chats',
        tag: 'Chat',
        error: e,
      );
    }
    if (mounted) setState(() => _loadingList = false);
  }

  Future<void> _send() async {
    if (_sending || _selected.isEmpty) return;
    setState(() => _sending = true);
    try {
      final result = await ref.read(chatServiceProvider).forwardMessage(
            messageId: widget.messageId,
            recipientIds: _selected.toList(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      AppLogger.warning(
        'Forward failed',
        tag: 'Chat',
        error: e,
      );
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = ref.watch(chatListPreviewProvider).items;
    final query = _search.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? items
        : items
            .where((item) => item.name.toLowerCase().contains(query))
            .toList();
    final height = MediaQuery.sizeOf(context).height * 0.55;

    return AppBottomSheetCard(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spacingMD,
                AppSpacing.spacingMD,
                AppSpacing.spacingMD,
                AppSpacing.spacingSM,
              ),
              child: AppText(
                'Forward',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingMD,
              ),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search chats',
                ),
              ),
            ),
            Expanded(
              child: _loadingList
                  ? Center(
                      child: SizedBox(
                        width: AppSpacing.spacingXL,
                        height: AppSpacing.spacingXL,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : visible.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.spacingLG),
                            child: AppText(
                              'No chats to forward to',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final item = visible[index];
                            final selected = _selected.contains(item.id);
                            return Semantics(
                              button: true,
                              selected: selected,
                              label: item.name,
                              child: ListTile(
                                onTap: () {
                                  setState(() {
                                    if (selected) {
                                      _selected.remove(item.id);
                                    } else if (_selected.length <
                                        ChatForwardAttribution.maxRecipients) {
                                      _selected.add(item.id);
                                    }
                                  });
                                },
                                leading: AvatarWidget(
                                  imageUrl: item.avatarUrl,
                                  radius: 20,
                                  fallbackInitial: item.name,
                                ),
                                title: AppText(
                                  item.name,
                                  style: theme.textTheme.titleSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: AppSvgIcon(
                                  assetPath: AppIcons.checkCircle,
                                  size: 22,
                                  color: selected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.28),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spacingMD),
              child: ElevatedButton(
                onPressed: _sending || _selected.isEmpty ? null : _send,
                child: AppText(
                  _sending
                      ? 'Sending…'
                      : _selected.length <= 1
                          ? 'Forward'
                          : 'Forward to ${_selected.length}',
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
