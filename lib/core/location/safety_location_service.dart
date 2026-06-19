import 'package:geolocator/geolocator.dart';

import '../../features/safety/data/models/safe_place.dart';
import '../../shared/services/safety_api_service.dart';
import 'location_required_exception.dart';
import 'location_service.dart';

/// GPS helpers for safety flows (SOS, live share, nearby safe places).
class SafetyLocationService {
  SafetyLocationService({
    required LocationService locationService,
    required SafetyApiService safetyApi,
  })  : _locationService = locationService,
        _safetyApi = safetyApi;

  final LocationService _locationService;
  final SafetyApiService _safetyApi;

  /// Returns a fresh GPS fix or throws [LocationRequiredException].
  Future<Position> requireCurrentPosition() async {
    final permission = await _locationService.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw const LocationRequiredException(permanentlyDenied: true);
    }

    final position = await _locationService.getCurrentPosition(
      accuracy: LocationAccuracy.high,
    );

    if (position == null) {
      throw const LocationRequiredException();
    }

    return position;
  }

  Future<Map<String, dynamic>> sendEmergencyAlert({
    String alertType = 'emergency',
    String? message,
  }) async {
    final position = await requireCurrentPosition();

    return _safetyApi.sendEmergencyAlert({
      'location': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'alert_type': alertType,
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  Future<Map<String, dynamic>> shareLiveLocation({
    required int durationMinutes,
    String? message,
  }) async {
    final position = await requireCurrentPosition();

    return _safetyApi.shareLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      durationMinutes: durationMinutes,
      message: message,
    );
  }

  Future<List<SafePlace>> getNearbySafePlaces({int radiusKm = 5}) async {
    final position = await requireCurrentPosition();

    final payload = await _safetyApi.getNearbySafePlaces(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusKm: radiusKm,
    );

    return SafePlace.listFromApiPayload(payload);
  }
}
