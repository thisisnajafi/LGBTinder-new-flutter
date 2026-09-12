import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/feature_flags_provider.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/utils/media_url.dart';
import '../models/shared_media_item.dart';
import '../../utils/chat_visual_media.dart';

class ChatInfoCacheSnapshot {
  const ChatInfoCacheSnapshot({
    this.media = const [],
    this.pinnedCount = 0,
  });

  final List<SharedMediaItem> media;
  final int pinnedCount;

  ChatInfoCacheSnapshot copyWith({
    List<SharedMediaItem>? media,
    int? pinnedCount,
  }) {
    return ChatInfoCacheSnapshot(
      media: media ?? this.media,
      pinnedCount: pinnedCount ?? this.pinnedCount,
    );
  }
}

class ChatInfoCache extends Notifier<Map<int, ChatInfoCacheSnapshot>> {
  static const _prefsKey = 'lgbtfinder_chat_info_cache_v1';

  SharedPreferences? get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Map<int, ChatInfoCacheSnapshot> build() => _read(_prefs);

  ChatInfoCacheSnapshot snapshotFor(int userId) =>
      state[userId] ?? const ChatInfoCacheSnapshot();

  Future<void> saveMedia(int userId, List<SharedMediaItem> items) async {
    if (userId <= 0) return;
    final existing = snapshotFor(userId);
    final normalized = [
      for (final item in items)
        if (MediaUrl.resolve(item.url) != null)
          SharedMediaItem(
            url: MediaUrl.resolve(item.url)!,
            isVideo: item.isVideo,
            messageId: item.messageId,
          ),
    ];
    state = {
      ...state,
      userId: existing.copyWith(media: normalized),
    };
    await _persist();
    await ChatVisualMedia.prefetchUrlsList(
      normalized.map((item) => item.url),
    );
  }

  Future<void> mergeMedia(int userId, List<SharedMediaItem> incoming) async {
    if (userId <= 0 || incoming.isEmpty) return;
    final existing = snapshotFor(userId).media;
    final seen = <String>{};
    final merged = <SharedMediaItem>[];
    for (final item in [...incoming, ...existing]) {
      final url = MediaUrl.resolve(item.url);
      if (url == null || !seen.add(url)) continue;
      merged.add(
        SharedMediaItem(
          url: url,
          isVideo: item.isVideo,
          messageId: item.messageId,
        ),
      );
    }
    await saveMedia(userId, merged);
  }

  Future<void> savePinnedCount(int userId, int count) async {
    if (userId <= 0) return;
    final existing = snapshotFor(userId);
    if (existing.pinnedCount == count && state.containsKey(userId)) return;
    state = {
      ...state,
      userId: existing.copyWith(pinnedCount: count < 0 ? 0 : count),
    };
    await _persist();
  }

  Future<void> clear() async {
    state = {};
    await _prefs?.remove(_prefsKey);
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final encoded = <String, dynamic>{
      for (final entry in state.entries)
        entry.key.toString(): {
          'pinned_count': entry.value.pinnedCount,
          'media': entry.value.media.map((item) => item.toJson()).toList(),
        },
    };
    await prefs.setString(_prefsKey, jsonEncode(encoded));
  }

  static Map<int, ChatInfoCacheSnapshot> _read(SharedPreferences? prefs) {
    if (prefs == null) return {};
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <int, ChatInfoCacheSnapshot>{};
      decoded.forEach((key, value) {
        final id = int.tryParse(key.toString()) ?? 0;
        if (id <= 0 || value is! Map) return;
        final map = Map<String, dynamic>.from(value);
        final mediaRaw = map['media'];
        final media = mediaRaw is List
            ? mediaRaw
                .whereType<Map>()
                .map(
                  (item) => SharedMediaItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where((item) => item.url.isNotEmpty)
                .toList()
            : const <SharedMediaItem>[];
        out[id] = ChatInfoCacheSnapshot(
          media: media,
          pinnedCount: (map['pinned_count'] as num?)?.toInt() ?? 0,
        );
      });
      return out;
    } catch (e) {
      AppLogger.warning(
        'Failed to decode chat info cache',
        tag: 'Chat',
        error: e,
      );
      return {};
    }
  }
}

final chatInfoCacheProvider =
    NotifierProvider<ChatInfoCache, Map<int, ChatInfoCacheSnapshot>>(
  ChatInfoCache.new,
);
