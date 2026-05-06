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
import '../../features/reference_data/providers/reference_data_providers.dart';
import '../../features/matching/providers/likes_providers.dart';
import '../../features/matching/providers/matching_provider.dart';
import '../../features/matching/data/models/match.dart' as match_models;
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import '../../widgets/match/match_screen.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';

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
  bool _isMatched = false;

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

      // Check match status
      final matchingNotifier = ref.read(matchingProvider.notifier);
      final isMatched = await matchingNotifier.checkMatchStatus(widget.userId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isMatched = isMatched;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = _userFriendlyProfileError(e);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = _userFriendlyProfileError(null, fallback: e.toString());
          _isLoading = false;
        });
      }
    }
  }

  /// Show a user-friendly message for profile load errors; hide raw SQL/server messages.
  String _userFriendlyProfileError(ApiError? e, {String? fallback}) {
    if (e != null) {
      if (e.code == 500 ||
          (e.message.contains('SQLSTATE') || e.message.contains("doesn't exist"))) {
        return "We're having trouble loading this profile. Please try again later.";
      }
      return e.message;
    }
    final msg = fallback ?? 'Something went wrong';
    if (msg.contains('SQLSTATE') || msg.contains("doesn't exist") || msg.contains('500')) {
      return "We're having trouble loading this profile. Please try again later.";
    }
    return msg;
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
    final target = Uri(
      path: AppRoutes.chat,
      queryParameters: {
        'userId': _profile!.id.toString(),
        'userName': '${_profile!.firstName} ${_profile!.lastName}'.trim(),
      },
    ).toString();
    context.push(target);
  }

  List<String>? _mapIdsToTitles(List<int>? ids, List<dynamic> refs) {
    if (ids == null || ids.isEmpty) return null;
    final byId = <int, String>{};
    for (final item in refs) {
      final id = item.id as int?;
      final title = item.title as String?;
      if (id != null && title != null && title.isNotEmpty) {
        byId[id] = title;
      }
    }
    final values = ids
        .map((id) => byId[id] ?? id.toString())
        .toSet()
        .toList(growable: false);
    return values.isEmpty ? null : values;
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
    final interestsRef = ref.watch(interestsProvider).valueOrNull ?? const [];
    final jobsRef = ref.watch(jobsProvider).valueOrNull ?? const [];
    final educationsRef = ref.watch(educationLevelsProvider).valueOrNull ?? const [];
    final languagesRef = ref.watch(languagesProvider).valueOrNull ?? const [];
    final preferredGendersRef = ref.watch(preferredGendersProvider).valueOrNull ?? const [];
    final relationGoalsRef = ref.watch(relationshipGoalsProvider).valueOrNull ?? const [];

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
                            isVerified: _profile!.isVerified ?? false,
                            isPremium: _profile!.isPremium ?? false,
                            isOnline: _profile!.isOnline ?? false,
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
                                // Open image viewer - implementation needed
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Image viewer will be implemented for image $index'),
                                  ),
                                );
                              },
                            ),
                          // Profile info sections
                          ProfileInfoSections(
                            interests: _mapIdsToTitles(_profile!.interests, interestsRef),
                            jobs: _mapIdsToTitles(_profile!.jobs, jobsRef),
                            educations: _mapIdsToTitles(_profile!.educations, educationsRef),
                            languages: _mapIdsToTitles(_profile!.languages, languagesRef),
                            gender: _profile!.gender,
                            preferredGenders: _mapIdsToTitles(_profile!.preferredGenders, preferredGendersRef),
                            relationGoals: _mapIdsToTitles(_profile!.relationGoals, relationGoalsRef),
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
                            isMatched: _isMatched,
                          ),
                        ],
                      ),
                    ),
    );
  }
}
