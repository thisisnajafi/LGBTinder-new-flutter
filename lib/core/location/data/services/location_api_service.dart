import '../../../constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/user_location.dart';

/// API client for user location endpoints.
class LocationApiService {
  LocationApiService(this._apiService);

  final ApiService _apiService;

  Future<UserLocation> getLocation() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.userLocation,
      fromJson: (json) => Map<String, dynamic>.from(json as Map),
      useCache: false,
    );

    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message.isNotEmpty ? response.message : 'Failed to load location');
    }

    return UserLocation.fromJson(response.data!);
  }

  Future<UserLocation> updateGps({
    required double latitude,
    required double longitude,
    int? accuracyMeters,
    String source = 'gps',
  }) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiEndpoints.userLocation,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
        'source': source,
      },
      fromJson: (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message.isNotEmpty ? response.message : 'Failed to update location');
    }

    return UserLocation.fromJson(response.data!);
  }

  Future<UserLocation> updateAdministrativeLocation({
    int? countryId,
    int? cityId,
  }) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiEndpoints.userLocation,
      data: {
        if (countryId != null) 'country_id': countryId,
        if (cityId != null) 'city_id': cityId,
      },
      fromJson: (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message.isNotEmpty ? response.message : 'Failed to update location');
    }

    return UserLocation.fromJson(response.data!);
  }
}
