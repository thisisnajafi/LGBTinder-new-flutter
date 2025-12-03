// Widget: CustomizableProfileWidget
// Customizable profile display
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import 'profile_header.dart';
import 'profile_bio.dart';
import 'photo_gallery.dart';
import 'profile_info_sections.dart';
import 'profile_action_buttons.dart';

/// Customizable profile widget
/// Composable profile display with optional sections
class CustomizableProfileWidget extends ConsumerWidget {
  final Map<String, dynamic> userData;
  final bool showHeader;
  final bool showBio;
  final bool showGallery;
  final bool showInfoSections;
  final bool showActionButtons;
  final bool isEditable;
  final Function()? onEdit;
  final Function(int userId)? onLike;
  final Function(int userId)? onSuperlike;
  final Function(int userId)? onMessage;

  const CustomizableProfileWidget({
    Key? key,
    required this.userData,
    this.showHeader = true,
    this.showBio = true,
    this.showGallery = true,
    this.showInfoSections = true,
    this.showActionButtons = true,
    this.isEditable = false,
    this.onEdit,
    this.onLike,
    this.onSuperlike,
    this.onMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader)
            ProfileHeader(
              name: userData['name'] ?? 'User',
              age: userData['age'],
              location: userData['location'],
              avatarUrl: userData['avatar_url'],
              isVerified: userData['is_verified'] ?? false,
              isPremium: userData['is_premium'] ?? false,
              isOnline: userData['is_online'] ?? false,
              onEdit: isEditable ? onEdit : null,
            ),
          if (showBio)
            ProfileBio(
              bio: userData['bio'],
              onEdit: isEditable ? onEdit : null,
              isEditable: isEditable,
            ),
          if (showGallery)
            PhotoGallery(
              imageUrls: (userData['gallery_images'] as List<dynamic>?)
                      ?.map((e) => e['url'] as String)
                      .toList() ??
                  [],
              isEditable: isEditable,
              onAddPhoto: isEditable ? () {} : null,
            ),
          if (showInfoSections)
            ProfileInfoSections(
              interests: (userData['interests'] as List<dynamic>?)
                  ?.map((e) => e['title'] as String)
                  .toList(),
              jobs: (userData['jobs'] as List<dynamic>?)
                  ?.map((e) => e['title'] as String)
                  .toList(),
              educations: (userData['educations'] as List<dynamic>?)
                  ?.map((e) => e['title'] as String)
                  .toList(),
              languages: (userData['languages'] as List<dynamic>?)
                  ?.map((e) => e['title'] as String)
                  .toList(),
              musicGenres: (userData['music_genres'] as List<dynamic>?)
                  ?.map((e) => e['title'] as String)
                  .toList(),
              relationGoals: (userData['relation_goals'] as List<dynamic>?)
                  ?.map((e) => e['title'] as String)
                  .toList(),
              gender: userData['gender'] as String?,
              preferredGenders: (userData['preferred_genders'] as List<dynamic>?)
                  ?.map((e) => e['title'] as String)
                  .toList(),
              height: userData['height'] as int?,
              weight: userData['weight'] as int?,
              smoke: userData['smoke'] as bool?,
              drink: userData['drink'] as bool?,
              gym: userData['gym'] as bool?,
            ),
          if (showActionButtons && !isEditable)
            ProfileActionButtons(
              onLike: onLike != null
                  ? () => onLike?.call(userData['id'] ?? 0)
                  : null,
              onSuperlike: onSuperlike != null
                  ? () => onSuperlike?.call(userData['id'] ?? 0)
                  : null,
              onMessage: onMessage != null
                  ? () => onMessage?.call(userData['id'] ?? 0)
                  : null,
              isLiked: userData['is_liked'] ?? false,
              isSuperliked: userData['is_superliked'] ?? false,
              isMatched: userData['is_matched'] ?? false,
            ),
        ],
      ),
    );
  }
}
