/// User Image model
class UserImage {
  final int id;
  final int userId;
  final String path;
  final String type; // 'profile', 'gallery'
  final int order;
  final bool isPrimary;
  final Map<String, dynamic>? sizes;

  UserImage({
    required this.id,
    required this.userId,
    required this.path,
    required this.type,
    required this.order,
    required this.isPrimary,
    this.sizes,
  });

  /// Get the full URL for the image
  String get url => path.startsWith('http')
      ? path
      : 'https://your-cdn-domain.com/storage/$path'; // Replace with actual CDN domain

  /// Alias for url property for backward compatibility
  String get imageUrl => url;

  /// Get thumbnail URL
  String get thumbnailUrl {
    if (sizes != null && sizes!.containsKey('thumbnail')) {
      final thumbnailPath = sizes!['thumbnail'];
      return thumbnailPath.startsWith('http')
          ? thumbnailPath
          : 'https://your-cdn-domain.com/storage/$thumbnailPath'; // Replace with actual CDN domain
    }

    // Fallback to original thumbnail logic if sizes not available
    final pathInfo = path.split('/');
    final filename = pathInfo.last.split('.');
    final extension = filename.last;
    final name = filename.first;
    final dir = pathInfo.sublist(0, pathInfo.length - 1).join('/');

    return 'https://your-cdn-domain.com/storage/$dir/thumbnails/${name}_thumb.$extension'; // Replace with actual CDN domain
  }

  /// Get URL for specific size
  String? getSizeUrl(String size) {
    if (sizes != null && sizes!.containsKey(size)) {
      final sizePath = sizes![size];
      return sizePath.startsWith('http')
          ? sizePath
          : 'https://your-cdn-domain.com/storage/$sizePath'; // Replace with actual CDN domain
    }
    return null;
  }

  factory UserImage.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['id'] == null) {
      throw FormatException('UserImage.fromJson: id is required but was null');
    }
    if (json['user_id'] == null) {
      throw FormatException('UserImage.fromJson: user_id is required but was null');
    }
    if (json['path'] == null) {
      throw FormatException('UserImage.fromJson: path is required but was null');
    }
    if (json['type'] == null) {
      throw FormatException('UserImage.fromJson: type is required but was null');
    }
    
    return UserImage(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      userId: (json['user_id'] is int) ? json['user_id'] as int : int.parse(json['user_id'].toString()),
      path: json['path'].toString(),
      type: json['type'].toString(),
      order: json['order'] != null ? ((json['order'] is int) ? json['order'] as int : int.tryParse(json['order'].toString()) ?? 0) : 0,
      isPrimary: json['is_primary'] == true || json['is_primary'] == 1,
      sizes: json['sizes'] != null && json['sizes'] is Map
          ? Map<String, dynamic>.from(json['sizes'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'path': path,
      'type': type,
      'order': order,
      'is_primary': isPrimary,
      'sizes': sizes,
    };
  }

  UserImage copyWith({
    int? id,
    int? userId,
    String? path,
    String? type,
    int? order,
    bool? isPrimary,
    Map<String, dynamic>? sizes,
  }) {
    return UserImage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      path: path ?? this.path,
      type: type ?? this.type,
      order: order ?? this.order,
      isPrimary: isPrimary ?? this.isPrimary,
      sizes: sizes ?? this.sizes,
    );
  }
}
