import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/feature_flags_provider.dart';
import '../models/call.dart';
import '../../utils/call_log_labels.dart';

/// On-device call log for the messenger inbox and chat timelines.
class CallHistoryLocalCache extends Notifier<Map<int, List<Call>>> {
  static const _prefsKey = 'lgbtfinder_call_history_peer_v1';
  static const _inboxKey = 'lgbtfinder_call_history_inbox_v1';
  static const _maxPerPeer = 50;
  static const _maxInbox = 80;

  SharedPreferences? get _prefs => ref.read(sharedPreferencesProvider);
  List<Call> _inbox = const [];

  @override
  Map<int, List<Call>> build() {
    final prefs = _prefs;
    _inbox = _readList(prefs?.getString(_inboxKey));
    return _readPeers(prefs);
  }

  List<Call> inboxCalls() => List<Call>.unmodifiable(_inbox);

  List<Call> callsForPeer(int peerUserId) {
    if (peerUserId <= 0) return const [];
    final fromPeer = state[peerUserId];
    if (fromPeer != null && fromPeer.isNotEmpty) {
      return List<Call>.unmodifiable(fromPeer);
    }
    return List<Call>.unmodifiable(
      _inbox.where(
        (call) =>
            call.callerId == peerUserId || call.receiverId == peerUserId,
      ),
    );
  }

  Future<void> saveForPeer(int peerUserId, List<Call> calls) async {
    if (peerUserId <= 0) return;
    final terminal = _dedupe(
      calls.where((call) => CallLogLabels.isTerminalStatus(call.status)),
    );
    state = {
      ...state,
      peerUserId: terminal.take(_maxPerPeer).toList(growable: false),
    };
    await _persistPeers();
  }

  Future<void> upsertCall(int peerUserId, Call call) async {
    if (peerUserId <= 0 || !CallLogLabels.isTerminalStatus(call.status)) {
      return;
    }
    final existing = state[peerUserId] ?? const <Call>[];
    await saveForPeer(peerUserId, [call, ...existing]);
    _inbox = _dedupe([call, ..._inbox]).take(_maxInbox).toList(growable: false);
    await _persistInbox();
  }

  Future<void> saveInbox({
    required List<Call> calls,
    required int currentUserId,
  }) async {
    final terminal = _dedupe(calls).take(_maxInbox).toList(growable: false);
    _inbox = terminal;

    final byPeer = <int, List<Call>>{};
    for (final call in terminal) {
      final peerId = currentUserId > 0
          ? call.getOtherParticipantId(currentUserId)
          : 0;
      if (peerId <= 0) continue;
      byPeer.putIfAbsent(peerId, () => <Call>[]).add(call);
    }
    state = {
      for (final entry in byPeer.entries)
        entry.key:
            _dedupe(entry.value).take(_maxPerPeer).toList(growable: false),
    };
    await _persistPeers();
    await _persistInbox();
  }

  Future<void> clear() async {
    _inbox = const [];
    state = {};
    await _prefs?.remove(_prefsKey);
    await _prefs?.remove(_inboxKey);
  }

  Future<void> _persistPeers() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final encoded = <String, dynamic>{
      for (final entry in state.entries)
        entry.key.toString():
            entry.value.map((call) => call.toJson()).toList(),
    };
    await prefs.setString(_prefsKey, jsonEncode(encoded));
  }

  Future<void> _persistInbox() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(
      _inboxKey,
      jsonEncode(_inbox.map((call) => call.toJson()).toList()),
    );
  }

  static List<Call> _dedupe(Iterable<Call> calls) {
    final seen = <int>{};
    final out = <Call>[];
    for (final call in calls) {
      final id = call.id > 0 ? call.id : int.tryParse(call.callId) ?? 0;
      if (id <= 0 || !seen.add(id)) continue;
      out.add(call);
    }
    out.sort((a, b) => b.timelineTimestamp.compareTo(a.timelineTimestamp));
    return out;
  }

  static List<Call> _readList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return _dedupe(
        decoded.whereType<Map>().map(
              (item) => Call.fromJson(Map<String, dynamic>.from(item)),
            ),
      );
    } catch (_) {
      return const [];
    }
  }

  static Map<int, List<Call>> _readPeers(SharedPreferences? prefs) {
    if (prefs == null) return {};
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <int, List<Call>>{};
      decoded.forEach((key, value) {
        final id = int.tryParse(key.toString()) ?? 0;
        if (id <= 0 || value is! List) return;
        out[id] = _dedupe(
          value.whereType<Map>().map(
                (item) => Call.fromJson(Map<String, dynamic>.from(item)),
              ),
        );
      });
      return out;
    } catch (_) {
      return {};
    }
  }
}

final callHistoryLocalCacheProvider =
    NotifierProvider<CallHistoryLocalCache, Map<int, List<Call>>>(
  CallHistoryLocalCache.new,
);
