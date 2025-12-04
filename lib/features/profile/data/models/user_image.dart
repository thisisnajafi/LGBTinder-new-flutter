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
    return UserImage(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      path: json['path'] as String,
      type: json['type'] as String,
      order: json['order'] as int? ?? 0,
      isPrimary: json['is_primary'] as bool? ?? false,
      sizes: json['sizes'] as Map<String, dynamic>?,
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
