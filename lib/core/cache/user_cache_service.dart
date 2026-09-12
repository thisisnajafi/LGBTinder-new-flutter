import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/matching/data/models/match.dart';
import '../../features/profile/data/models/user_profile.dart';
import '../services/app_logger.dart';
import 'cache_config.dart';
import 'cache_entry.dart';
import 'isolate_json.dart';

/// Memory + disk cache for user profiles, match lists, and related JSON.
class UserCacheService {
  UserCacheService(this._prefs);

  final SharedPreferences _prefs;

  final Map<String, CacheEntry<UserProfile>> _profileMemory = {};
  final Map<String, CacheEntry<List<Match>>> _matchListMemory = {};

  String _diskKey(String logicalKey) => '${CacheConfig.diskPrefix}$logicalKey';

  // ── Profiles ──────────────────────────────────────────────────────────────

  CacheEntry<UserProfile>? getProfileFromMemory(String userId) =>
      _profileMemory[userId];

  Future<CacheEntry<UserProfile>?> getProfile(
    String userId, {
    bool allowStale = false,
  }) async {
    final mem = _profileMemory[userId];
    if (mem != null && (allowStale || !mem.isExpired)) {
      return mem;
    }

    try {
      final raw = _prefs.getString(_diskKey(CacheConfig.userProfileKey(userId)));
      if (raw == null) return mem;

      final json = await decodeJsonMapIsolate(raw);
      final entry = CacheEntry<UserProfile>.fromJson(
        json: json,
        dataFromJson: UserProfile.fromJson,
      );

      if (!allowStale && entry.isExpired) {
        return mem;
      }

      _profileMemory[userId] = entry;
      return entry;
    } catch (e) {
      AppLogger.warning(
        'UserCacheService.getProfile failed',
        tag: 'Cache',
        error: e,
      );
      return mem;
    }
  }

  Future<void> saveProfile(
    String userId,
    UserProfile profile, {
    required Duration ttl,
  }) async {
    final entry = CacheEntry<UserProfile>(
      data: profile,
      cachedAt: DateTime.now(),
      ttl: ttl,
    );
    _profileMemory[userId] = entry;

    try {
      await _prefs.setString(
        _diskKey(CacheConfig.userProfileKey(userId)),
        jsonEncode(
          entry.toJson(dataToJson: (d) => d.toJson()),
        ),
      );
    } catch (e) {
      AppLogger.warning(
        'UserCacheService.saveProfile failed',
        tag: 'Cache',
        error: e,
      );
    }
  }

  Future<void> invalidateProfile(String userId) async {
    _profileMemory.remove(userId);
    await _prefs.remove(_diskKey(CacheConfig.userProfileKey(userId)));
    await _prefs.remove(_diskKey(CacheConfig.avatarKey(userId)));
    for (var i = 0; i < 20; i++) {
      await _prefs.remove(
        _diskKey(CacheConfig.profileImageKey(userId, i)),
      );
    }
  }

  // ── Match list ────────────────────────────────────────────────────────────

  Future<CacheEntry<List<Match>>?> getMatchList(
    String userId, {
    bool allowStale = false,
  }) async {
    final mem = _matchListMemory[userId];
    if (mem != null && (allowStale || !mem.isExpired)) {
      return mem;
    }

    try {
      final raw =
          _prefs.getString(_diskKey(CacheConfig.matchListKey(userId)));
      if (raw == null) return mem;

      final map = await decodeJsonMapIsolate(raw);
      final list = (map['data'] as List)
          .map((e) => Match.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final entry = CacheEntry<List<Match>>(
        data: list,
        cachedAt: DateTime.parse(map['cached_at'] as String),
        ttl: Duration(milliseconds: map['ttl_ms'] as int),
      );

      if (!allowStale && entry.isExpired) return mem;

      _matchListMemory[userId] = entry;
      return entry;
    } catch (e) {
      AppLogger.warning(
        'UserCacheService.getMatchList failed',
        tag: 'Cache',
        error: e,
      );
      return mem;
    }
  }

  Future<void> saveMatchList(
    String userId,
    List<Match> matches,
  ) async {
    final entry = CacheEntry<List<Match>>(
      data: matches,
      cachedAt: DateTime.now(),
      ttl: CacheConfig.matchListTtl,
    );
    _matchListMemory[userId] = entry;

    try {
      await _prefs.setString(
        _diskKey(CacheConfig.matchListKey(userId)),
        jsonEncode({
          'data': matches.map((m) => m.toJson()).toList(),
          'cached_at': entry.cachedAt.toIso8601String(),
          'ttl_ms': entry.ttl.inMilliseconds,
        }),
      );
    } catch (e) {
      AppLogger.warning(
        'UserCacheService.saveMatchList failed',
        tag: 'Cache',
        error: e,
      );
    }
  }

  Future<void> invalidateMatchList(String userId) async {
    _matchListMemory.remove(userId);
    await _prefs.remove(_diskKey(CacheConfig.matchListKey(userId)));
  }

  Future<void> invalidateDiscoveryCards(String userId) async {
    await _prefs.remove(_diskKey(CacheConfig.discoveryCardsKey(userId)));
  }

  Future<void> invalidateAll() async {
    _profileMemory.clear();
    _matchListMemory.clear();

    final keys = _prefs.getKeys().where(
      (k) => k.startsWith(CacheConfig.diskPrefix),
    );
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
