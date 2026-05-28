import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/payments/data/models/plan_limits.dart';
import '../../features/payments/data/models/subscription_plan.dart';
import '../../features/payments/data/models/superlike_pack.dart';
import '../services/app_logger.dart';
import 'cache_config.dart';

/// Disk-backed session cache for superlikes, subscription, and tier.
class SessionDataCacheService {
  SessionDataCacheService(this._prefs);

  final SharedPreferences _prefs;

  static const String superlikesRemainingKey = 'superlikes:remaining';
  static const String superlikesPacksKey = 'superlikes:packs';
  static const String subscriptionStatusKey = 'subscription:status';
  static const String userTierKey = 'user:tier';

  static const Duration superlikesRemainingTtl = Duration(minutes: 30);
  static const Duration superlikesPacksTtl = Duration(hours: 1);
  static const Duration subscriptionStatusTtl = Duration(minutes: 15);
  static const Duration userTierTtl = Duration(minutes: 15);

  int? _memoryRemaining;

  String _diskKey(String logicalKey) => '${CacheConfig.diskPrefix}$logicalKey';

  // ── Superlikes remaining ──────────────────────────────────────────────────

  int? getSuperlikesRemainingSync() {
    if (_memoryRemaining != null) {
      return _memoryRemaining;
    }
    return _readIntEntry(superlikesRemainingKey, superlikesRemainingTtl);
  }

  Future<int?> getSuperlikesRemaining() async {
    final value = getSuperlikesRemainingSync();
    if (value != null) {
      AppLogger.info(
        'Cache hit: $superlikesRemainingKey = $value',
        tag: 'SessionCache',
      );
    } else {
      AppLogger.info('Cache miss: $superlikesRemainingKey', tag: 'SessionCache');
    }
    return value;
  }

  Future<void> setSuperlikesRemaining(int count) async {
    _memoryRemaining = count;
    await _writeIntEntry(
      superlikesRemainingKey,
      count,
      superlikesRemainingTtl,
    );
    AppLogger.info(
      'Cache write: $superlikesRemainingKey = $count',
      tag: 'SessionCache',
    );
  }

  // ── Superlike packs ───────────────────────────────────────────────────────

  List<SuperlikePack>? getSuperlikePacksSync() {
    return _readListEntry<SuperlikePack>(
      superlikesPacksKey,
      superlikesPacksTtl,
      SuperlikePack.fromJson,
    );
  }

  Future<List<SuperlikePack>?> getSuperlikePacks() async {
    final value = getSuperlikePacksSync();
    if (value != null) {
      AppLogger.info(
        'Cache hit: $superlikesPacksKey (${value.length} packs)',
        tag: 'SessionCache',
      );
    } else {
      AppLogger.info('Cache miss: $superlikesPacksKey', tag: 'SessionCache');
    }
    return value;
  }

  Future<void> setSuperlikePacks(List<SuperlikePack> packs) async {
    await _writeListEntry(
      superlikesPacksKey,
      packs,
      superlikesPacksTtl,
      (p) => p.toJson(),
    );
    AppLogger.info(
      'Cache write: $superlikesPacksKey (${packs.length} packs)',
      tag: 'SessionCache',
    );
  }

  // ── Subscription status ───────────────────────────────────────────────────

  SubscriptionStatus? getSubscriptionStatusSync() {
    return _readObjectEntry<SubscriptionStatus>(
      subscriptionStatusKey,
      subscriptionStatusTtl,
      SubscriptionStatus.fromJson,
    );
  }

  Future<SubscriptionStatus?> getSubscriptionStatus() async {
    final value = getSubscriptionStatusSync();
    if (value != null) {
      AppLogger.info('Cache hit: $subscriptionStatusKey', tag: 'SessionCache');
    } else {
      AppLogger.info('Cache miss: $subscriptionStatusKey', tag: 'SessionCache');
    }
    return value;
  }

  Future<void> setSubscriptionStatus(SubscriptionStatus status) async {
    await _writeObjectEntry(
      subscriptionStatusKey,
      status,
      subscriptionStatusTtl,
      (s) => s.toJson(),
    );
    AppLogger.info('Cache write: $subscriptionStatusKey', tag: 'SessionCache');
  }

  // ── User tier ─────────────────────────────────────────────────────────────

  String? getUserTierSync() {
    return _readStringEntry(userTierKey, userTierTtl);
  }

  Future<String?> getUserTier() async {
    final value = getUserTierSync();
    if (value != null) {
      AppLogger.info('Cache hit: $userTierKey = $value', tag: 'SessionCache');
    } else {
      AppLogger.info('Cache miss: $userTierKey', tag: 'SessionCache');
    }
    return value;
  }

  Future<void> setUserTier(String tier) async {
    await _writeStringEntry(userTierKey, tier, userTierTtl);
    AppLogger.info('Cache write: $userTierKey = $tier', tag: 'SessionCache');
  }

  /// Build [SuperlikeInfo] from cached remaining count only.
  SuperlikeInfo? superlikeInfoFromCache() {
    final remaining = getSuperlikesRemainingSync();
    if (remaining == null) return null;
    return SuperlikeInfo(
      canSuperlike: remaining > 0,
      totalRemaining: remaining,
      dailyRemaining: remaining,
      extraPacksRemaining: 0,
      dailyLimit: remaining,
      dailyUsed: 0,
    );
  }

  Future<void> applySuperlikeSendResponse({
    required int superlikesRemaining,
    required Map<String, dynamic> subscriptionJson,
  }) async {
    await setSuperlikesRemaining(superlikesRemaining);

    final tier = subscriptionJson['tier']?.toString();
    if (tier != null && tier.isNotEmpty) {
      await setUserTier(tier);
    }

    final existing = getSubscriptionStatusSync();
    final merged = SubscriptionStatus.fromJson({
      ...?existing?.toJson(),
      ...subscriptionJson,
      'is_active': subscriptionJson['is_active'] ?? existing?.isActive ?? false,
    });
    await setSubscriptionStatus(merged);
  }

  Future<void> clearAll() async {
    _memoryRemaining = null;
    for (final key in [
      superlikesRemainingKey,
      superlikesPacksKey,
      subscriptionStatusKey,
      userTierKey,
    ]) {
      await _prefs.remove(_diskKey(key));
    }
    AppLogger.info('Session cache cleared', tag: 'SessionCache');
  }

  // ── Storage helpers ───────────────────────────────────────────────────────

  int? _readIntEntry(String logicalKey, Duration ttl) {
    final raw = _prefs.getString(_diskKey(logicalKey));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(map['cached_at'] as String);
      if (_isExpired(cachedAt, ttl)) return null;
      return map['value'] as int;
    } catch (e) {
      AppLogger.error(
        'Cache read error: $logicalKey',
        tag: 'SessionCache',
        error: e,
      );
      return null;
    }
  }

  Future<void> _writeIntEntry(String logicalKey, int value, Duration ttl) async {
    await _prefs.setString(
      _diskKey(logicalKey),
      jsonEncode({
        'value': value,
        'cached_at': DateTime.now().toIso8601String(),
        'ttl_ms': ttl.inMilliseconds,
      }),
    );
  }

  String? _readStringEntry(String logicalKey, Duration ttl) {
    final raw = _prefs.getString(_diskKey(logicalKey));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(map['cached_at'] as String);
      if (_isExpired(cachedAt, ttl)) return null;
      return map['value'] as String?;
    } catch (e) {
      AppLogger.error(
        'Cache read error: $logicalKey',
        tag: 'SessionCache',
        error: e,
      );
      return null;
    }
  }

  Future<void> _writeStringEntry(
    String logicalKey,
    String value,
    Duration ttl,
  ) async {
    await _prefs.setString(
      _diskKey(logicalKey),
      jsonEncode({
        'value': value,
        'cached_at': DateTime.now().toIso8601String(),
        'ttl_ms': ttl.inMilliseconds,
      }),
    );
  }

  List<T>? _readListEntry<T>(
    String logicalKey,
    Duration ttl,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _prefs.getString(_diskKey(logicalKey));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(map['cached_at'] as String);
      if (_isExpired(cachedAt, ttl)) return null;
      final list = (map['value'] as List)
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return list;
    } catch (e) {
      AppLogger.error(
        'Cache read error: $logicalKey',
        tag: 'SessionCache',
        error: e,
      );
      return null;
    }
  }

  Future<void> _writeListEntry<T>(
    String logicalKey,
    List<T> values,
    Duration ttl,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    await _prefs.setString(
      _diskKey(logicalKey),
      jsonEncode({
        'value': values.map(toJson).toList(),
        'cached_at': DateTime.now().toIso8601String(),
        'ttl_ms': ttl.inMilliseconds,
      }),
    );
  }

  T? _readObjectEntry<T>(
    String logicalKey,
    Duration ttl,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _prefs.getString(_diskKey(logicalKey));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(map['cached_at'] as String);
      if (_isExpired(cachedAt, ttl)) return null;
      return fromJson(Map<String, dynamic>.from(map['value'] as Map));
    } catch (e) {
      AppLogger.error(
        'Cache read error: $logicalKey',
        tag: 'SessionCache',
        error: e,
      );
      return null;
    }
  }

  Future<void> _writeObjectEntry<T>(
    String logicalKey,
    T value,
    Duration ttl,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    await _prefs.setString(
      _diskKey(logicalKey),
      jsonEncode({
        'value': toJson(value),
        'cached_at': DateTime.now().toIso8601String(),
        'ttl_ms': ttl.inMilliseconds,
      }),
    );
  }

  bool _isExpired(DateTime cachedAt, Duration ttl) {
    return DateTime.now().isAfter(cachedAt.add(ttl));
  }
}
