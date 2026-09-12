import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/incoming_call_data.dart';
import 'package:lgbtindernew/features/profile/data/models/user_image.dart';
import 'package:lgbtindernew/features/profile/presentation/widgets/own_profile/profile_photo_utils.dart';

void main() {
  group('IncomingCallData', () {
    test('prefers primary_image_url over avatar crop', () {
      final data = IncomingCallData.fromPayload({
        'call_id': 42,
        'call_type': 'video',
        'caller_id': 7,
        'caller_name': 'Abolfazl',
        'caller_avatar': 'https://cdn.example/avatar-250.jpg',
        'caller': {
          'id': 7,
          'name': 'Abolfazl',
          'avatar_url': 'https://cdn.example/avatar-250.jpg',
          'primary_image_url': 'https://cdn.example/primary-full.jpg',
        },
      });

      expect(data, isNotNull);
      expect(data!.callerAvatar, 'https://cdn.example/primary-full.jpg');
    });
  });

  group('primaryProfilePhotoUrl', () {
    test('returns the full primary image, not a sized crop', () {
      final images = [
        UserImage(
          id: 1,
          userId: 7,
          path: 'https://cdn.example/primary-full.jpg',
          type: 'profile',
          order: 0,
          isPrimary: true,
          sizes: const {
            '250x250': 'https://cdn.example/avatar-250.jpg',
          },
        ),
        UserImage(
          id: 2,
          userId: 7,
          path: 'https://cdn.example/gallery.jpg',
          type: 'gallery',
          order: 1,
          isPrimary: false,
        ),
      ];

      expect(
        primaryProfilePhotoUrl(images),
        'https://cdn.example/primary-full.jpg',
      );
      expect(
        primaryProfileImage(images)?.avatarDisplayUrl,
        'https://cdn.example/avatar-250.jpg',
      );
    });

    test('skips a non-primary gallery photo that is first in the list', () {
      final images = [
        UserImage(
          id: 2,
          userId: 7,
          path: 'https://cdn.example/gallery-placeholder.jpg',
          type: 'gallery',
          order: 1,
          isPrimary: false,
        ),
        UserImage(
          id: 1,
          userId: 7,
          path: 'https://cdn.example/primary-full.jpg',
          type: 'profile',
          order: 0,
          isPrimary: true,
        ),
      ];

      expect(images.first.path, 'https://cdn.example/gallery-placeholder.jpg');
      expect(
        primaryProfileImage(images)?.imageUrl,
        'https://cdn.example/primary-full.jpg',
      );
    });
  });

  group('firstNonPrimaryProfilePhotoUrl', () {
    test('returns the first gallery photo, not the primary', () {
      final images = [
        UserImage(
          id: 1,
          userId: 7,
          path: 'https://cdn.example/primary-full.jpg',
          type: 'profile',
          order: 0,
          isPrimary: true,
        ),
        UserImage(
          id: 3,
          userId: 7,
          path: 'https://cdn.example/gallery-later.jpg',
          type: 'gallery',
          order: 2,
          isPrimary: false,
        ),
        UserImage(
          id: 2,
          userId: 7,
          path: 'https://cdn.example/gallery-first.jpg',
          type: 'gallery',
          order: 1,
          isPrimary: false,
        ),
      ];

      expect(
        firstNonPrimaryProfilePhotoUrl(images),
        'https://cdn.example/gallery-first.jpg',
      );
    });

    test('returns null when the user only has a primary photo', () {
      final images = [
        UserImage(
          id: 1,
          userId: 7,
          path: 'https://cdn.example/primary-full.jpg',
          type: 'profile',
          order: 0,
          isPrimary: true,
        ),
      ];

      expect(firstNonPrimaryProfilePhotoUrl(images), isNull);
    });
  });
}
