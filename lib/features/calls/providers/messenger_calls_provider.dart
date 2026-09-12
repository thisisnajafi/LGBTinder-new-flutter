import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/peer_avatar_cache.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../features/user/providers/user_providers.dart';
import '../data/local/call_history_local_cache.dart';
import '../data/models/call.dart';
import '../data/repositories/call_repository.dart';
import '../utils/call_log_labels.dart';
import '../utils/messenger_call_groups.dart';
import 'call_providers.dart';

class MessengerCallsState {
  final bool isLoading;
  final List<Call> calls;
  final Call? liveCall;
  final String? error;

  const MessengerCallsState({
    this.isLoading = false,
    this.calls = const [],
    this.liveCall,
    this.error,
  });

  MessengerCallsState copyWith({
    bool? isLoading,
    List<Call>? calls,
    Call? liveCall,
    String? error,
    bool clearError = false,
    bool clearLiveCall = false,
  }) {
    return MessengerCallsState(
      isLoading: isLoading ?? this.isLoading,
      calls: calls ?? this.calls,
      liveCall: clearLiveCall ? null : (liveCall ?? this.liveCall),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MessengerCallsNotifier extends StateNotifier<MessengerCallsState> {
  MessengerCallsNotifier(this._repository, this._ref)
      : super(const MessengerCallsState());

  final CallRepository _repository;
  final Ref _ref;
  bool _hasLoaded = false;
  bool _inFlight = false;
  bool _disposed = false;

  Future<void> load({bool force = false}) async {
    if (_inFlight) return;
    if (!_hasLoaded && state.calls.isEmpty) {
      final cached = _hydrateFromCache();
      if (cached.isNotEmpty) {
        state = MessengerCallsState(calls: cached, isLoading: true);
      }
    }
    if (_hasLoaded && !force && state.calls.isNotEmpty) {
      unawaited(_refreshSilent());
      return;
    }
    _inFlight = true;
    try {
      await Future<void>(() {});
      if (_disposed) return;
      if (state.calls.isEmpty) {
        state = state.copyWith(isLoading: true, clearError: true);
      }
      await _fetch();
    } finally {
      _inFlight = false;
    }
  }

  Future<void> refresh() => load(force: true);

  /// New incoming call while the Calls tab may already be showing history.
  void refreshOnIncoming() {
    unawaited(_refreshSilent());
  }

  /// Pusher / local hang-up: leave "Connecting…" and drop the live banner.
  void applyRemoteStatus({
    required int callId,
    required String status,
  }) {
    if (callId <= 0 || _disposed) return;
    final normalized = status.toLowerCase();
    final calls = <Call>[];
    var found = false;
    for (final call in state.calls) {
      if (call.id == callId) {
        found = true;
        calls.add(
          call.copyWith(
            status: normalized,
            endedAt: CallLogLabels.isTerminalStatus(normalized)
                ? (call.endedAt ?? DateTime.now())
                : call.endedAt,
          ),
        );
      } else {
        calls.add(call);
      }
    }

    final live = state.liveCall;
    final liveMatches = live != null && live.id == callId;
    final liveStillLive =
        liveMatches && CallLogLabels.isLiveStatus(normalized);

    state = state.copyWith(
      calls: found ? calls : state.calls,
      liveCall: liveStillLive ? live.copyWith(status: normalized) : live,
      clearLiveCall: liveMatches && !liveStillLive,
    );

    unawaited(_refreshSilent());
  }

  List<Call> callsForPeer(int peerUserId) {
    if (peerUserId <= 0) return const [];
    final live = state.calls
        .where(
          (call) =>
              call.callerId == peerUserId || call.receiverId == peerUserId,
        )
        .toList();
    if (live.isNotEmpty) return live;
    return _ref
        .read(callHistoryLocalCacheProvider.notifier)
        .callsForPeer(peerUserId);
  }

  List<Call> _hydrateFromCache() {
    final cache = _ref.read(callHistoryLocalCacheProvider.notifier);
    return _withAvatars(cache.inboxCalls());
  }

  Future<void> _refreshSilent() async {
    try {
      await _fetch(keepExistingOnError: true);
    } catch (e) {
      AppLogger.warning(
        'Silent messenger calls refresh failed',
        tag: 'Chat',
        error: e,
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _fetch({bool keepExistingOnError = false}) async {
    try {
      final history = await _repository.getCallHistory(limit: 50);
      Call? live;
      try {
        live = await _repository.getActiveCall();
      } catch (e) {
        AppLogger.warning(
          'Active call lookup failed',
          tag: 'Chat',
          error: e,
        );
        live = null;
      }
      if (_disposed) return;
      _hasLoaded = true;
      final withAvatars = _withAvatars(history);
      state = MessengerCallsState(
        calls: withAvatars,
        liveCall: live != null && live.id > 0 ? live : null,
      );
      final me = _ref.read(cachedCurrentUserProvider).asData?.value.id ?? 0;
      unawaited(
        _ref.read(callHistoryLocalCacheProvider.notifier).saveInbox(
              calls: withAvatars,
              currentUserId: me,
            ),
      );
      unawaited(_rememberAvatars(withAvatars, me));
    } catch (e) {
      if (keepExistingOnError || _disposed) return;
      if (state.calls.isNotEmpty) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load calls',
      );
    }
  }

  List<Call> _withAvatars(List<Call> calls) {
    final me = _ref.read(cachedCurrentUserProvider).asData?.value.id ?? 0;
    final cached = _ref.read(peerAvatarCacheProvider);
    if (me <= 0) return calls;
    return [
      for (final call in calls) _callWithResolvedAvatar(call, me, cached),
    ];
  }

  Call _callWithResolvedAvatar(
    Call call,
    int currentUserId,
    Map<int, String> cached,
  ) {
    final peerId = call.getOtherParticipantId(currentUserId);
    final incoming = messengerPeerAvatar(call, currentUserId);
    final picked = MediaUrl.pick(
      userId: peerId,
      incoming: incoming,
      cached: cached[peerId],
    );
    if (picked == null || picked == incoming) return call;
    final isOutgoing = call.callerId == currentUserId;
    final peer = isOutgoing ? call.receiver : call.caller;
    if (peer == null) return call;
    final updatedPeer = peer.copyWith(avatarUrl: picked);
    return call.copyWith(
      receiver: isOutgoing ? updatedPeer : call.receiver,
      caller: isOutgoing ? call.caller : updatedPeer,
    );
  }

  Future<void> _rememberAvatars(List<Call> calls, int currentUserId) async {
    if (currentUserId <= 0) return;
    final urls = <int, String?>{};
    for (final call in calls) {
      final peerId = call.getOtherParticipantId(currentUserId);
      urls[peerId] = messengerPeerAvatar(call, currentUserId);
    }
    await _ref.read(peerAvatarCacheProvider.notifier).rememberMany(urls);
  }
}

final messengerCallsProvider =
    StateNotifierProvider<MessengerCallsNotifier, MessengerCallsState>((ref) {
  return MessengerCallsNotifier(ref.watch(callRepositoryProvider), ref);
});
