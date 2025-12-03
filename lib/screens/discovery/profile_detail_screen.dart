// Screen: ProfileDetailScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/profile_bio.dart';
import '../../widgets/profile/photo_gallery.dart';
import '../../widgets/profile/profile_info_sections.dart';
import '../../widgets/profile/profile_action_buttons.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../widgets/error_handling/error_display_widget.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../features/profile/data/models/user_profile.dart';
import '../../features/matching/providers/likes_providers.dart';
import '../../features/matching/data/models/match.dart' as match_models;
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import '../../pages/chat_page.dart';
import '../../widgets/match/match_screen.dart';
import 'package:go_router/go_router.dart';

/// Profile detail screen - View detailed user profile
class ProfileDetailScreen extends ConsumerStatefulWidget {
  final int userId;

  const ProfileDetailScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final profileService = ref.read(profileServiceProvider);
      final profile = await profileService.getUserProfile(widget.userId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLike() async {
    if (_profile == null) return;

    try {
      final likesService = ref.read(likesServiceProvider);
      final response = await likesService.likeUser(_profile!.id);

      if (mounted) {
        if (response.isMatch) {
          _showMatchDialog(response.match as match_models.Match?);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Liked!'),
              backgroundColor: AppColors.onlineGreen,
            ),
          );
        }
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to like user',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to like user',
        );
      }
    }
  }

  Future<void> _handleSuperlike() async {
    if (_profile == null) return;

    try {
      final likesService = ref.read(likesServiceProvider);
      final response = await likesService.superlikeUser(_profile!.id);

      if (mounted) {
        if (response.isMatch) {
          _showMatchDialog(response.match as match_models.Match?);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Superliked!'),
              backgroundColor: AppColors.accentYellow,
            ),
          );
        }
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to superlike user',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to superlike user',
        );
      }
    }
  }

  void _handleMessage() {
    if (_profile == null) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(userId: _profile!.id),
      ),
    );
  }

  void _showMatchDialog(match_models.Match? match) {
    if (match == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => MatchScreen(
        match: match,
        onSendMessage: () {
          Navigator.pop(context);
          _handleMessage();
        },
        onKeepSwiping: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  int? _calculateAge() {
    if (_profile?.birthDate == null) return null;
    try {
      final birthDate = DateTime.parse(_profile!.birthDate!);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  String _getLocation() {
    final parts = <String>[];
    if (_profile?.city != null && _profile!.city!.isNotEmpty) {
      parts.add(_profile!.city!);
    }
    if (_profile?.country != null && _profile!.country!.isNotEmpty) {
      parts.add(_profile!.country!);
    }
    return parts.isEmpty ? 'Location not set' : parts.join(', ');
  }

  String? _getPrimaryImageUrl() {
    if (_profile?.images == null || _profile!.images!.isEmpty) return null;
    final primaryImage = _profile!.images!.firstWhere(
      (img) => img.isPrimary,
      orElse: () => _profile!.images!.first,
    );
    return primaryImage.imageUrl;
  }

  List<String> _getImageUrls() {
    if (_profile?.images == null || _profile!.images!.isEmpty) return [];
    return _profile!.images!.map((img) => img.imageUrl).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Profile',
        showBackButton: true,
      ),
      body: _isLoading
          ? LoadingIndicator(message: 'Loading profile...')
          : _hasError
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage ?? 'Failed to load profile',
                  onRetry: _loadProfile,
                )
              : _profile == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Profile header
                          ProfileHeader(
                            name: '${_profile!.firstName} ${_profile!.lastName}',
                            age: _calculateAge(),
                            location: _getLocation(),
                            avatarUrl: _getPrimaryImageUrl(),
                            isVerified: false, // UserProfile doesn't have isVerified yet
                            isPremium: false, // UserProfile doesn't have isPremium yet
                            isOnline: false, // UserProfile doesn't have isOnline yet
                          ),
                          // Bio
                          if (_profile!.profileBio != null && _profile!.profileBio!.isNotEmpty)
                            ProfileBio(
                              bio: _profile!.profileBio!,
                            ),
                          // Photo gallery
                          if (_getImageUrls().isNotEmpty)
                            PhotoGallery(
                              imageUrls: _getImageUrls(),
                              onImageTap: (index, url) {
                                // TODO: Open image viewer
                              },
                            ),
                          // Profile info sections
                          ProfileInfoSections(
                            interests: null, // IDs need to be converted to names via reference data
                            jobs: null, // IDs need to be converted to names via reference data
                            educations: null, // IDs need to be converted to names via reference data
                            languages: null, // IDs need to be converted to names via reference data
                            gender: _profile!.gender,
                            preferredGenders: null, // IDs need to be converted to names
                            height: _profile!.height,
                            weight: _profile!.weight,
                            smoke: _profile!.smoke,
                            drink: _profile!.drink,
                            gym: _profile!.gym,
                          ),
                          SizedBox(height: AppSpacing.spacingXXL),
                          // Action buttons
                          ProfileActionButtons(
                            onLike: _handleLike,
                            onSuperlike: _handleSuperlike,
                            onMessage: _handleMessage,
                            isMatched: false, // TODO: Check if matched
                          ),
                        ],
                      ),
                    ),
    );
  }
}
