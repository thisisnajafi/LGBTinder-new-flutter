import '../../../data/models/user_image.dart';

/// Primary profile photo (hero avatar), excluding gallery tiles.
UserImage? primaryProfileImage(List<UserImage>? images) {
  if (images == null || images.isEmpty) return null;
  for (final image in images) {
    if (image.isPrimary || image.type == 'profile') {
      return image;
    }
  }
  return images.first;
}

/// Full-size URL of the first primary profile photo (not the 250x250 avatar crop).
String? primaryProfilePhotoUrl(List<UserImage>? images) {
  final primary = primaryProfileImage(images);
  if (primary == null) return null;
  final url = primary.imageUrl.trim();
  return url.isEmpty ? null : url;
}

/// First extra photo that is not the primary/hero image, sorted by gallery order.
UserImage? firstNonPrimaryProfileImage(List<UserImage>? images) {
  if (images == null || images.isEmpty) return null;

  final primary = primaryProfileImage(images);
  final primaryId = primary?.id;
  final primaryIdentity =
      primary == null ? '' : _photoIdentity(primary.imageUrl);

  bool isSameAsPrimary(UserImage image) {
    if (primaryId != null && primaryId > 0 && image.id == primaryId) {
      return true;
    }
    if (primaryIdentity.isEmpty) return false;
    return _photoIdentity(image.imageUrl) == primaryIdentity;
  }

  final gallery = galleryProfileImages(images);
  for (final image in gallery) {
    if (image.imageUrl.trim().isEmpty || isSameAsPrimary(image)) continue;
    return image;
  }

  final extras = [...images]..sort((a, b) => a.order.compareTo(b.order));
  for (final image in extras) {
    if (image.isPrimary || image.type == 'profile') continue;
    if (image.imageUrl.trim().isEmpty || isSameAsPrimary(image)) continue;
    return image;
  }

  return null;
}

/// Full-size URL of the first non-primary photo, or null when the user has none.
String? firstNonPrimaryProfilePhotoUrl(List<UserImage>? images) {
  final extra = firstNonPrimaryProfileImage(images);
  if (extra == null) return null;
  final url = extra.imageUrl.trim();
  return url.isEmpty ? null : url;
}

/// Gallery photos only (up to 6), sorted by order.
List<UserImage> galleryProfileImages(List<UserImage>? images) {
  if (images == null || images.isEmpty) return const [];
  return images.where((image) => image.type == 'gallery').toList()
    ..sort((a, b) => a.order.compareTo(b.order));
}

/// Same photo at different signed/query URLs still counts as one slide.
String _photoIdentity(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return '';
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return trimmed;
  return '${uri.scheme}://${uri.host}${uri.path}';
}

List<String> uniqueProfilePhotoUrls(Iterable<String> urls) {
  final seen = <String>{};
  final unique = <String>[];
  for (final url in urls) {
    final identity = _photoIdentity(url);
    if (identity.isEmpty || !seen.add(identity)) continue;
    unique.add(url.trim());
  }
  return unique;
}

/// All profile photos for carousel (primary first, then gallery by order).
List<String> orderedProfilePhotoUrls(List<UserImage>? images) {
  if (images == null || images.isEmpty) return const [];

  final primary = primaryProfileImage(images);
  final gallery = galleryProfileImages(images);
  final urls = <String>[];

  if (primary != null && primary.imageUrl.isNotEmpty) {
    urls.add(primary.imageUrl);
  }
  for (final image in gallery) {
    if (image.imageUrl.isNotEmpty) {
      urls.add(image.imageUrl);
    }
  }

  if (urls.isEmpty) {
    urls.addAll(
      images.map((image) => image.imageUrl).where((u) => u.isNotEmpty),
    );
  }
  return uniqueProfilePhotoUrls(urls);
}
