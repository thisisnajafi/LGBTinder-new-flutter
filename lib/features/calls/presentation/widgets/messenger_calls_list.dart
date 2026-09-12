import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/peer_avatar_cache.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../../../core/widgets/app_list_view.dart';
import '../../../../features/user/providers/user_providers.dart';
import '../../../../widgets/error_handling/empty_state.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/chat/chat_list_loading.dart';
import '../../data/models/call.dart';
import '../../pages/outgoing_call_page.dart';
import '../../providers/messenger_calls_provider.dart';
import '../../utils/call_log_labels.dart';
import '../../utils/call_navigation.dart';
import '../../utils/messenger_call_groups.dart';
import 'messenger_active_call_banner.dart';
import 'messenger_call_row.dart';

/// Messenger Calls tab: live banner + grouped recents.
class MessengerCallsList extends ConsumerStatefulWidget {
  const MessengerCallsList({
    super.key,
    required this.filter,
    required this.searchQuery,
    required this.listPadding,
  });

  final MessengerCallFilter filter;
  final String searchQuery;
  final EdgeInsets listPadding;

  @override
  ConsumerState<MessengerCallsList> createState() => _MessengerCallsListState();
}

class _MessengerCallsListState extends ConsumerState<MessengerCallsList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(messengerCallsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messengerCallsProvider);
    final me = ref.watch(cachedCurrentUserProvider).asData?.value.id ?? 0;
    final live = state.liveCall;
    final query = widget.searchQuery.trim().toLowerCase();
    final avatarCache = ref.watch(peerAvatarCacheProvider);

    var groups = groupMessengerCalls(
      calls: state.calls,
      currentUserId: me,
      filter: widget.filter,
    );
    if (query.isNotEmpty) {
      groups = groups
          .where((g) => g.peerName.toLowerCase().contains(query))
          .toList();
    }
    groups = [
      for (final group in groups)
        MessengerCallGroup(
          peerId: group.peerId,
          peerName: group.peerName,
          peerAvatarUrl: MediaUrl.pick(
            userId: group.peerId,
            incoming: group.peerAvatarUrl,
            cached: avatarCache[group.peerId],
          ),
          latest: group.latest,
          count: group.count,
          missedCount: group.missedCount,
        ),
    ];

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (live != null &&
              live.id > 0 &&
              CallLogLabels.isLiveStatus(live.status))
            MessengerActiveCallBanner(
              call: live,
              currentUserId: me,
              onTap: () => openExistingCallPage(
                context: context,
                call: live,
                currentUserId: me,
              ),
            ),
          Expanded(child: _buildBody(state, groups, me)),
        ],
      ),
    );
  }

  Widget _buildBody(
    MessengerCallsState state,
    List<MessengerCallGroup> groups,
    int me,
  ) {
    if (state.isLoading && state.calls.isEmpty) {
      return const ChatListLoading(itemCount: 5);
    }
    if (state.error != null && state.calls.isEmpty) {
      return ErrorDisplayWidget(
        errorMessage: state.error!,
        onRetry: () => ref.read(messengerCallsProvider.notifier).refresh(),
      );
    }
    if (groups.isEmpty) {
      return SingleChildScrollView(
        physics: AppScroll.bouncing,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.35,
          child: EmptyState(
            title: widget.filter == MessengerCallFilter.missed
                ? 'No missed calls'
                : 'No calls yet',
            message: widget.filter == MessengerCallFilter.missed
                ? 'Missed voice and video calls will show up here.'
                : 'Voice and video calls with matches will show up here.',
            iconPath: AppIcons.call,
          ),
        ),
      );
    }

    return AppListView.separated(
      physics: AppScroll.forChat(context),
      padding: widget.listPadding.copyWith(bottom: AppSpacing.spacingLG),
      itemCount: groups.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.spacingXS),
      itemBuilder: (context, index) {
        final group = groups[index];
        return MessengerCallRow(
          group: group,
          currentUserId: me,
          onOpenHistory: () => openPeerCallHistory(
            context: context,
            userId: group.peerId,
            name: group.peerName,
            avatarUrl: group.peerAvatarUrl,
          ),
          onCallAgain: () => _redial(group.latest, group),
        );
      },
    );
  }

  void _redial(Call call, MessengerCallGroup group) {
    if (CallLogLabels.isLiveStatus(call.status)) {
      openExistingCallPage(
        context: context,
        call: call,
        currentUserId: ref.read(cachedCurrentUserProvider).asData?.value.id ?? 0,
      );
      return;
    }
    startOutgoingCall(
      context: context,
      ref: ref,
      recipientId: group.peerId,
      recipientName: group.peerName,
      recipientAvatarUrl: group.peerAvatarUrl,
      type: call.isVideoCall ? OutgoingCallType.video : OutgoingCallType.voice,
    );
  }
}
