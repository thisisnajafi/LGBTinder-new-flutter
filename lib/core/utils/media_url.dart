import '../constants/api_endpoints.dart';

/// Normalizes storage/CDN photo URLs so list, chat, and disk cache share one key.
class MediaUrl {
  MediaUrl._();

  static bool isPlaceholder(String? value) {
    if (value == null) return true;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return true;
    final lower = trimmed.toLowerCase();
    return lower.contains('default-avatar') ||
        lower.contains('placeholder') ||
        lower.endsWith('/images/user.png');
  }

  /// Absolute http(s) URL, or null when the value cannot be loaded.
  static String? resolve(String? pathOrUrl) {
    if (isPlaceholder(pathOrUrl)) return null;
    final trimmed = pathOrUrl!.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/storage/')) {
      return '${ApiEndpoints.apiOrigin}$trimmed';
    }
    if (trimmed.startsWith('storage/')) {
      return '${ApiEndpoints.apiOrigin}/$trimmed';
    }

    final clean =
        trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return '${ApiEndpoints.storageUrl}/$clean';
  }

  /// Path identity that ignores signed query strings and size variants.
  static String photoIdentity(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    final uri = Uri.tryParse(trimmed);
    var path = (uri != null && (uri.hasScheme || uri.path.isNotEmpty))
        ? uri.path
        : trimmed;
    path = path.toLowerCase();
    path = path.replaceAll(
      RegExp(r'_(50x50|100x100|250x250|full|thumb)(?:_blur)?'),
      '',
    );
    path = path.replaceAll(
      RegExp(r'/(50x50|100x100|250x250|full|thumbnails)/'),
      '/',
    );
    return path;
  }

  static bool samePhoto(String a, String b) {
    final left = photoIdentity(a);
    final right = photoIdentity(b);
    return left.isNotEmpty && left == right;
  }

  static String cacheKey({int? userId, required String url}) {
    final identity = photoIdentity(url);
    if (userId != null && userId > 0) {
      return 'peer_avatar_${userId}_$identity';
    }
    return identity.isNotEmpty ? identity : url;
  }

  /// Prefer a previously cached file URL when the API sends the same photo
  /// at a different size or with a new query string.
  static String? pick({
    required int userId,
    String? incoming,
    String? cached,
  }) {
    final resolved = resolve(incoming);
    final cachedResolved = resolve(cached);
    if (resolved == null) return cachedResolved;
    if (cachedResolved == null) return resolved;
    if (samePhoto(resolved, cachedResolved)) return cachedResolved;
    return resolved;
  }
}
