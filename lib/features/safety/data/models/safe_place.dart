/// Nearby hospital / police / fire station from safety API.
class SafePlace {
  final String name;
  final String type;
  final String? address;
  final String? distanceLabel;
  final double? distanceKm;
  final String? phone;
  final double latitude;
  final double longitude;

  const SafePlace({
    required this.name,
    required this.type,
    this.address,
    this.distanceLabel,
    this.distanceKm,
    this.phone,
    required this.latitude,
    required this.longitude,
  });

  factory SafePlace.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'];
    double? lat;
    double? lng;
    if (coords is Map) {
      lat = _toDouble(coords['latitude']);
      lng = _toDouble(coords['longitude']);
    }

    return SafePlace(
      name: json['name']?.toString() ?? 'Safe place',
      type: json['type']?.toString() ?? 'public',
      address: json['address']?.toString(),
      distanceLabel: json['distance']?.toString(),
      distanceKm: _toDouble(json['distance_km']),
      phone: json['phone']?.toString(),
      latitude: lat ?? 0,
      longitude: lng ?? 0,
    );
  }

  static List<SafePlace> listFromApiPayload(Map<String, dynamic> payload) {
    dynamic raw = payload['data'] ?? payload['places'] ?? payload;
    if (raw is Map<String, dynamic> && raw['data'] is List) {
      raw = raw['data'];
    }
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((item) => SafePlace.fromJson(Map<String, dynamic>.from(item)))
        .where((place) => place.latitude != 0 || place.longitude != 0)
        .toList();
  }

  String get mapsUrl => 'https://www.google.com/maps?q=$latitude,$longitude';

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
