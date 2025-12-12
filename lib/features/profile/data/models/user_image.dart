import '../../../../core/constants/api_endpoints.dart';

/// User Image model
/// FIXED: Task 5.3.2 - Updated to use centralized storageUrl instead of hardcoded CDN domain
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

  /// Build full URL from path using centralized storage URL
  static String _buildUrl(String pathOrUrl) {
    if (pathOrUrl.isEmpty) return '';
    if (pathOrUrl.startsWith('http')) return pathOrUrl;
    // Remove leading slash if present to avoid double slashes
    final cleanPath = pathOrUrl.startsWith('/') ? pathOrUrl.substring(1) : pathOrUrl;
    return '${ApiEndpoints.storageUrl}/$cleanPath';
  }

  /// Get the full URL for the image
  String get url => _buildUrl(path);

  /// Alias for url property for backward compatibility
  String get imageUrl => url;

  /// Get thumbnail URL
  String get thumbnailUrl {
    if (sizes != null && sizes!.containsKey('thumbnail')) {
      final thumbnailPath = sizes!['thumbnail']?.toString() ?? '';
      return _buildUrl(thumbnailPath);
    }

    // Fallback to original thumbnail logic if sizes not available
    if (path.isEmpty) return '';
    final pathInfo = path.split('/');
    if (pathInfo.isEmpty) return url;
    
    final filename = pathInfo.last.split('.');
    if (filename.length < 2) return url; // No extension found, return original
    
    final extension = filename.last;
    final name = filename.first;
    final dir = pathInfo.sublist(0, pathInfo.length - 1).join('/');

    return _buildUrl('$dir/thumbnails/${name}_thumb.$extension');
  }

  /// Get URL for specific size
  String? getSizeUrl(String size) {
    if (sizes != null && sizes!.containsKey(size)) {
      final sizePath = sizes![size]?.toString() ?? '';
      if (sizePath.isEmpty) return null;
      return _buildUrl(sizePath);
    }
    return null;
  }

  factory UserImage.fromJson(Map<String, dynamic> json) {
    // Get ID - use 0 as fallback
    int imageId = 0;
    if (json['id'] != null) {
      imageId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['image_id'] != null) {
      imageId = (json['image_id'] is int) ? json['image_id'] as int : int.tryParse(json['image_id'].toString()) ?? 0;
    }
    
    // Get userId - use 0 as fallback
    int userId = 0;
    if (json['user_id'] != null) {
      userId = (json['user_id'] is int) ? json['user_id'] as int : int.tryParse(json['user_id'].toString()) ?? 0;
    } else if (json['userId'] != null) {
      userId = (json['userId'] is int) ? json['userId'] as int : int.tryParse(json['userId'].toString()) ?? 0;
    }
    
    // Get path - check multiple field names, default to empty string
    String imagePath = json['path']?.toString() ?? 
                       json['url']?.toString() ?? 
                       json['image_url']?.toString() ?? 
                       json['imageUrl']?.toString() ?? 
                       '';
    
    // Get type - default to 'gallery' if missing
    String imageType = json['type']?.toString() ?? 
                       json['image_type']?.toString() ?? 
                       'gallery';
    
    return UserImage(
      id: imageId,
      userId: userId,
      path: imagePath,
      type: imageType,
      order: json['order'] != null ? ((json['order'] is int) ? json['order'] as int : int.tryParse(json['order'].toString()) ?? 0) : 0,
      isPrimary: json['is_primary'] == true || json['is_primary'] == 1 || json['isPrimary'] == true || json['isPrimary'] == 1,
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
