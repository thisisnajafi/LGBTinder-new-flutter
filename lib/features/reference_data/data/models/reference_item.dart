/// Base model for reference data items (countries, cities, genders, etc.)
class ReferenceItem {
  final int id;
  final String title;
  final String? status;
  final String? code;
  final String? phoneCode;
  final String? stateProvince;
  final String? imageUrl;

  ReferenceItem({
    required this.id,
    required this.title,
    this.status,
    this.code,
    this.phoneCode,
    this.stateProvince,
    this.imageUrl,
  });

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
    );
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
    };
  }
}

