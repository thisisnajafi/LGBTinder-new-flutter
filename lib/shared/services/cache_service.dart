import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// PERFORMANCE FIX (Task 7.2.2): Cache duration presets for different data types
/// 
/// Usage:
/// ```dart
/// // Use preset durations
/// await cacheService.cacheDataWithDuration(
///   'user_profile_123',
///   profileData,
///   CacheDuration.profile,
/// );
/// ```
class CacheDuration {
  /// Reference data (countries, genders, etc.) - rarely changes
  static const Duration referenceData = Duration(hours: 24);
  
  /// User profile - changes occasionally
  static const Duration profile = Duration(minutes: 5);
  
  /// Match suggestions - changes frequently
  static const Duration matches = Duration(minutes: 1);
  
  /// Chat users list - changes very frequently
  static const Duration chatUsers = Duration(seconds: 30);
  
  /// Notifications - changes frequently
  static const Duration notifications = Duration(seconds: 30);
  
  /// Plan/subscription info - changes occasionally
  static const Duration planInfo = Duration(minutes: 5);
  
  /// Settings - rarely changes
  static const Duration settings = Duration(hours: 1);
  
  /// Default cache duration
  static const Duration defaultDuration = Duration(hours: 1);
}

/// PERFORMANCE FIX (Task 7.2.2): Enhanced service for caching API responses
/// 
/// Features:
/// - Configurable cache durations per data type
/// - Cache statistics and monitoring
/// - Selective cache invalidation
/// - Memory-efficient list caching
class CacheService {
  static const String _cachePrefix = 'api_cache_';
  static const String _cacheTimestampPrefix = 'api_cache_timestamp_';
  static const String _cacheDurationPrefix = 'api_cache_duration_';

  /// Get cached data with custom expiry check
  Future<T?> getCached<T>(
    String key, 
    T Function(Map<String, dynamic>) fromJson, {
    Duration? customExpiry,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_cacheTimestampPrefix$key';
      final durationKey = '$_cacheDurationPrefix$key';

      final cachedData = prefs.getString(cacheKey);
      final timestampStr = prefs.getString(timestampKey);

      if (cachedData == null || timestampStr == null) {
        return null;
      }

      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      
      // Get stored duration or use custom/default
      Duration expiry;
      if (customExpiry != null) {
        expiry = customExpiry;
      } else {
        final storedDurationMs = prefs.getInt(durationKey);
        expiry = storedDurationMs != null 
            ? Duration(milliseconds: storedDurationMs)
            : CacheDuration.defaultDuration;
      }
      
      // Check if cache is expired
      if (now.difference(timestamp) > expiry) {
        // Cache expired, remove it
        await _removeCache(prefs, key);
        return null;
      }

      final jsonData = jsonDecode(cachedData) as Map<String, dynamic>;
      return fromJson(jsonData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cache read error for key $key: $e');
      }
      return null;
    }
  }

  /// Get cached list data
  Future<List<T>?> getCachedList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? customExpiry,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_cacheTimestampPrefix$key';
      final durationKey = '$_cacheDurationPrefix$key';

      final cachedData = prefs.getString(cacheKey);
      final timestampStr = prefs.getString(timestampKey);

      if (cachedData == null || timestampStr == null) {
        return null;
      }

      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      
      // Get stored duration or use custom/default
      Duration expiry;
      if (customExpiry != null) {
        expiry = customExpiry;
      } else {
        final storedDurationMs = prefs.getInt(durationKey);
        expiry = storedDurationMs != null 
            ? Duration(milliseconds: storedDurationMs)
            : CacheDuration.defaultDuration;
      }
      
      // Check if cache is expired
      if (now.difference(timestamp) > expiry) {
        await _removeCache(prefs, key);
        return null;
      }

      final jsonList = jsonDecode(cachedData) as List<dynamic>;
      return jsonList
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cache list read error for key $key: $e');
      }
      return null;
    }
  }

  /// Cache data with configurable duration
  Future<void> cacheData(
    String key, 
    Map<String, dynamic> data, {
    Duration duration = CacheDuration.defaultDuration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_cacheTimestampPrefix$key';
      final durationKey = '$_cacheDurationPrefix$key';

      await prefs.setString(cacheKey, jsonEncode(data));
      await prefs.setString(timestampKey, DateTime.now().toIso8601String());
      await prefs.setInt(durationKey, duration.inMilliseconds);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cache write error for key $key: $e');
      }
    }
  }

  /// Cache list data with configurable duration
  Future<void> cacheListData<T>(
    String key,
    List<T> data,
    Map<String, dynamic> Function(T) toJson, {
    Duration duration = CacheDuration.defaultDuration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_cacheTimestampPrefix$key';
      final durationKey = '$_cacheDurationPrefix$key';

      final jsonList = data.map((item) => toJson(item)).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
      await prefs.setString(timestampKey, DateTime.now().toIso8601String());
      await prefs.setInt(durationKey, duration.inMilliseconds);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cache list write error for key $key: $e');
      }
    }
  }

  /// Clear cached data
  Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _removeCache(prefs, key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cache clear error for key $key: $e');
      }
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().toList();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || 
            key.startsWith(_cacheTimestampPrefix) ||
            key.startsWith(_cacheDurationPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Clear all cache error: $e');
      }
    }
  }

  /// Clear cache by pattern (useful for invalidating related caches)
  Future<void> clearCacheByPattern(String pattern) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().toList();
      
      for (final key in keys) {
        if (key.contains(pattern)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Clear cache by pattern error: $e');
      }
    }
  }

  /// Check if cache exists and is valid
  Future<bool> isCacheValid(String key, {Duration? customExpiry}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = '$_cacheTimestampPrefix$key';
      final durationKey = '$_cacheDurationPrefix$key';
      final timestampStr = prefs.getString(timestampKey);

      if (timestampStr == null) return false;

      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      
      Duration expiry;
      if (customExpiry != null) {
        expiry = customExpiry;
      } else {
        final storedDurationMs = prefs.getInt(durationKey);
        expiry = storedDurationMs != null 
            ? Duration(milliseconds: storedDurationMs)
            : CacheDuration.defaultDuration;
      }
      
      return now.difference(timestamp) <= expiry;
    } catch (e) {
      return false;
    }
  }

  /// Get cache statistics (for debugging/monitoring)
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int totalEntries = 0;
      int validEntries = 0;
      int expiredEntries = 0;
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          totalEntries++;
          final baseKey = key.replaceFirst(_cachePrefix, '');
          if (await isCacheValid(baseKey)) {
            validEntries++;
          } else {
            expiredEntries++;
          }
        }
      }
      
      return {
        'total_entries': totalEntries,
        'valid_entries': validEntries,
        'expired_entries': expiredEntries,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Helper to remove all cache keys for a given base key
  Future<void> _removeCache(SharedPreferences prefs, String key) async {
    await prefs.remove('$_cachePrefix$key');
    await prefs.remove('$_cacheTimestampPrefix$key');
    await prefs.remove('$_cacheDurationPrefix$key');
  }
}

/// PERFORMANCE FIX (Task 7.2.2): Cache keys for reference data
/// Centralized cache keys to ensure consistency
class CacheKeys {
  // Reference data keys (24-hour cache)
  static const String countries = 'ref_countries';
  static const String genders = 'ref_genders';
  static const String jobs = 'ref_jobs';
  static const String education = 'ref_education';
  static const String interests = 'ref_interests';
  static const String languages = 'ref_languages';
  static const String musicGenres = 'ref_music_genres';
  static const String relationGoals = 'ref_relation_goals';
  static const String preferredGenders = 'ref_preferred_genders';
  
  // User-specific keys
  static String userProfile(int userId) => 'user_profile_$userId';
  static String userPlan(int userId) => 'user_plan_$userId';
  static String userMatches(int userId) => 'user_matches_$userId';
  static String userChatUsers(int userId) => 'user_chat_users_$userId';
  static String userNotifications(int userId) => 'user_notifications_$userId';
}

