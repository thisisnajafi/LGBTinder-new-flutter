/// Normalized user location payload from `GET/PATCH /user/location`.
class UserLocation {
  final double? latitude;
  final double? longitude;
  final int? countryId;
  final int? cityId;
  final String? city;
  final String? country;
  final double? radiusSearchKm;
  final DateTime? locationUpdatedAt;
  final String? locationSource;
  final int? locationAccuracyMeters;

  const UserLocation({
    this.latitude,
    this.longitude,
    this.countryId,
    this.cityId,
    this.city,
    this.country,
    this.radiusSearchKm,
    this.locationUpdatedAt,
    this.locationSource,
    this.locationAccuracyMeters,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      countryId: _parseInt(json['country_id']),
      cityId: _parseInt(json['city_id']),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      radiusSearchKm: _parseDouble(json['radius_search_km']),
      locationUpdatedAt: json['location_updated_at'] != null
          ? DateTime.tryParse(json['location_updated_at'].toString())
          : null,
      locationSource: json['location_source']?.toString(),
      locationAccuracyMeters: _parseInt(json['location_accuracy_meters']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
