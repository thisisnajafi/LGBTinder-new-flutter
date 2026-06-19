/// Premium passport search location from `GET /user/location` → `passport`.
class PassportLocation {
  final bool active;
  final double? latitude;
  final double? longitude;
  final int? cityId;
  final String? city;
  final String? country;
  final DateTime? expiresAt;

  const PassportLocation({
    this.active = false,
    this.latitude,
    this.longitude,
    this.cityId,
    this.city,
    this.country,
    this.expiresAt,
  });

  factory PassportLocation.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const PassportLocation();
    }

    return PassportLocation(
      active: json['active'] == true || json['active'] == 1,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      cityId: _parseInt(json['city_id']),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
    );
  }

  String get displayLabel {
    final parts = [city, country].whereType<String>().where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'another city' : parts.join(', ');
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
