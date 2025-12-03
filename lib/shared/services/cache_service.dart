import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service for caching API responses
class CacheService {
  static const String _cachePrefix = 'api_cache_';
  static const String _cacheTimestampPrefix = 'api_cache_timestamp_';
  static const Duration _defaultCacheExpiry = Duration(hours: 1);

  /// Get cached data
  Future<T?> getCached<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_cacheTimestampPrefix$key';

      final cachedData = prefs.getString(cacheKey);
      final timestampStr = prefs.getString(timestampKey);

      if (cachedData == null || timestampStr == null) {
        return null;
      }

      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      
      // Check if cache is expired
      if (now.difference(timestamp) > _defaultCacheExpiry) {
        // Cache expired, remove it
        await prefs.remove(cacheKey);
        await prefs.remove(timestampKey);
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

  /// Cache data
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_cacheTimestampPrefix$key';

      await prefs.setString(cacheKey, jsonEncode(data));
      await prefs.setString(timestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cache write error for key $key: $e');
      }
    }
  }

  /// Clear cached data
  Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_cacheTimestampPrefix$key';

      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);
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
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_cacheTimestampPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Clear all cache error: $e');
      }
    }
  }

  /// Check if cache exists and is valid
  Future<bool> isCacheValid(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = '$_cacheTimestampPrefix$key';
      final timestampStr = prefs.getString(timestampKey);

      if (timestampStr == null) return false;

      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      
      return now.difference(timestamp) <= _defaultCacheExpiry;
    } catch (e) {
      return false;
    }
  }
}

