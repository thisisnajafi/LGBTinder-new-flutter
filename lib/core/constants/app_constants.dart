/// App-wide constants
class AppConstants {
  AppConstants._();

  /// Maximum gallery photos (excluding the primary profile photo).
  static const int maxGalleryPhotos = 6;

  /// Maximum primary profile photos.
  static const int maxPrimaryPhotos = 1;

  /// Primary + gallery combined cap shown on profile.
  static const int maxTotalProfilePhotos =
      maxPrimaryPhotos + maxGalleryPhotos;

  /// @deprecated Use [maxGalleryPhotos] or [maxTotalProfilePhotos].
  static const int maxProfilePhotos = maxTotalProfilePhotos;

  /// How many photos to preview on the own-profile grid before "View all".
  static const int profilePhotoGridPreview = 9;
}
