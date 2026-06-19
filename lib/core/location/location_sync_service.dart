import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/profile/providers/profile_page_cache_provider.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../services/app_logger.dart';
import 'data/models/user_location.dart';
import 'data/services/location_api_service.dart';
import 'location_service.dart';

/// Outcome of a location sync attempt.
enum LocationSyncResult {
  success,
  skippedDebounce,
  skippedRecent,
  skippedNoMovement,
  skippedPrivacy,
  permissionDenied,
  permissionDeniedForever,
  positionUnavailable,
  syncFailed,
}

/// Syncs device GPS to `PATCH /user/location` with debounce and movement thresholds.
class LocationSyncService {
  LocationSyncService({
    required Ref ref,
    required LocationService locationService,
    required LocationApiService locationApi,
  })  : _ref = ref,
        _locationService = locationService,
        _locationApi = locationApi;

  final Ref _ref;
  final LocationService _locationService;
  final LocationApiService _locationApi;

  static const _kLastSyncKey = 'location_last_sync_at';
  static const _kLastLatKey = 'location_last_lat';
  static const _kLastLngKey = 'location_last_lng';

  static const _debounce = Duration(seconds: 30);
  static const _staleAfter = Duration(hours: 1);
  static const _minMovementMeters = 500.0;

  DateTime? _lastAttempt;

  /// Background / app-launch sync when data is older than one hour.
  Future<LocationSyncResult> syncIfStale() {
    return syncIfNeeded(discoverOpen: false);
  }

  /// Discover tab sync — skips stale/movement checks but keeps debounce + privacy.
  Future<LocationSyncResult> syncForDiscover() {
    return syncIfNeeded(discoverOpen: true);
  }

  Future<LocationSyncResult> syncIfNeeded({
    required bool discoverOpen,
    bool force = false,
  }) async {
    final now = DateTime.now();
    if (!force &&
        _lastAttempt != null &&
        now.difference(_lastAttempt!) < _debounce) {
      return LocationSyncResult.skippedDebounce;
    }
    _lastAttempt = now;

    if (!discoverOpen && !force) {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_kLastSyncKey);
      if (lastSyncStr != null) {
        final lastSync = DateTime.tryParse(lastSyncStr);
        if (lastSync != null && now.difference(lastSync) < _staleAfter) {
          return LocationSyncResult.skippedRecent;
        }
      }
    }

    if (!await _isLocationSharingEnabled()) {
      return LocationSyncResult.skippedPrivacy;
    }

    final permission = await _locationService.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return LocationSyncResult.permissionDeniedForever;
    }

    final position = await _locationService.getCurrentPosition();
    if (position == null) {
      if (permission == LocationPermission.denied) {
        return LocationSyncResult.permissionDenied;
      }
      return LocationSyncResult.positionUnavailable;
    }

    if (!discoverOpen && !force) {
      final prefs = await SharedPreferences.getInstance();
      final lastLat = prefs.getDouble(_kLastLatKey);
      final lastLng = prefs.getDouble(_kLastLngKey);
      if (lastLat != null && lastLng != null) {
        final moved = Geolocator.distanceBetween(
          lastLat,
          lastLng,
          position.latitude,
          position.longitude,
        );
        if (moved < _minMovementMeters) {
          return LocationSyncResult.skippedNoMovement;
        }
      }
    }

    try {
      await _locationApi.updateGps(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy.isFinite ? position.accuracy.round() : null,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastSyncKey, now.toIso8601String());
      await prefs.setDouble(_kLastLatKey, position.latitude);
      await prefs.setDouble(_kLastLngKey, position.longitude);

      AppLogger.debug(
        'Location synced (${position.latitude}, ${position.longitude})',
        tag: 'LocationSync',
      );
      return LocationSyncResult.success;
    } catch (e, st) {
      AppLogger.error('Location sync failed', error: e, stackTrace: st, tag: 'LocationSync');
      return LocationSyncResult.syncFailed;
    }
  }

  /// When GPS is unavailable, ask backend to seed city centroid from profile city.
  Future<UserLocation?> syncCityCentroidFallback() async {
    final profile = _ref.read(profilePageCacheProvider).valueOrNull?.profile;
    final cityId = profile?.cityId;
    if (cityId == null) return null;

    try {
      return await _locationApi.updateAdministrativeLocation(
        countryId: profile?.countryId,
        cityId: cityId,
      );
    } catch (e, st) {
      AppLogger.error('City centroid fallback failed', error: e, stackTrace: st, tag: 'LocationSync');
      return null;
    }
  }

  Future<bool> _isLocationSharingEnabled() async {
    try {
      final privacy = await _ref.read(settingsRepositoryProvider).getPrivacySettings();
      return privacy.locationSharing;
    } catch (_) {
      return true;
    }
  }
}
