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

/// Gallery photos only (up to 6), sorted by order.
List<UserImage> galleryProfileImages(List<UserImage>? images) {
  if (images == null || images.isEmpty) return const [];
  return images.where((image) => image.type == 'gallery').toList()
    ..sort((a, b) => a.order.compareTo(b.order));
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
    if (image.imageUrl.isNotEmpty && !urls.contains(image.imageUrl)) {
      urls.add(image.imageUrl);
    }
  }

  if (urls.isEmpty) {
    return images.map((image) => image.imageUrl).where((u) => u.isNotEmpty).toList();
  }
  return urls;
}
