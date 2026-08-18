/// Base model for reference data items (countries, cities, genders, etc.)
class ReferenceItem {
  final int id;
  final String title;
  final String? status;
  final String? code;
  final String? phoneCode;
  final String? stateProvince;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  ReferenceItem({
    required this.id,
    required this.title,
    this.status,
    this.code,
    this.phoneCode,
    this.stateProvince,
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude! >= -90 &&
      latitude! <= 90 &&
      longitude! >= -180 &&
      longitude! <= 180;

  /// Keep one row per city name, preferring coordinates when duplicates exist.
  static List<ReferenceItem> uniqueByTitle(List<ReferenceItem> items) {
    final ranked = List<ReferenceItem>.from(items)
      ..sort((a, b) {
        final byName = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        if (byName != 0) return byName;
        final ac = a.hasCoordinates ? 0 : 1;
        final bc = b.hasCoordinates ? 0 : 1;
        if (ac != bc) return ac - bc;
        return a.id.compareTo(b.id);
      });

    final seen = <String>{};
    final unique = <ReferenceItem>[];
    for (final item in ranked) {
      final key = item.title.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) {
        continue;
      }
      unique.add(item);
    }
    return unique;
  }

  factory ReferenceItem.fromJson(Map<String, dynamic> json) {
    // Get ID - use 0 as fallback if not provided
    int refId = 0;
    if (json['id'] != null) {
      refId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    }
    
    // Get title from multiple possible fields
    String title = json['title']?.toString() ?? 
                   json['name']?.toString() ?? 
                   json['label']?.toString() ??
                   json['value']?.toString() ??
                   '';
    
    // If title is still empty, use code or a default
    if (title.isEmpty) {
      title = json['code']?.toString() ?? 'Item $refId';
    }
    
    return ReferenceItem(
      id: refId,
      title: title,
      status: json['status']?.toString(),
      code: json['code']?.toString(),
      phoneCode: json['phone_code']?.toString(),
      stateProvince: json['state_province']?.toString(),
      imageUrl: json['image_url']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (status != null) 'status': status,
      if (code != null) 'code': code,
      if (phoneCode != null) 'phone_code': phoneCode,
      if (stateProvince != null) 'state_province': stateProvince,
      if (imageUrl != null) 'image_url': imageUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

