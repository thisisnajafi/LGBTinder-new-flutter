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
