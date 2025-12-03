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
    return ReferenceItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      status: json['status'] as String?,
      code: json['code'] as String?,
      phoneCode: json['phone_code'] as String?,
      stateProvince: json['state_province'] as String?,
      imageUrl: json['image_url'] as String?,
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

