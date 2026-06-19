import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Thin wrapper around [Geolocator] for device GPS access.
class LocationService {
  static const Duration _positionTimeout = Duration(seconds: 10);

  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// One-shot current position with timeout; returns null when unavailable.
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) async {
    if (!await isLocationServiceEnabled()) {
      return getLastKnownPosition();
    }

    final permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await requestPermission();
      if (requested != LocationPermission.whileInUse &&
          requested != LocationPermission.always) {
        return null;
      }
    } else if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: _positionTimeout,
        ),
      ).timeout(_positionTimeout);
    } on TimeoutException {
      return getLastKnownPosition();
    } catch (_) {
      return getLastKnownPosition();
    }
  }

  Stream<Position> positionStream({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    int distanceFilterMeters = 100,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }
}
