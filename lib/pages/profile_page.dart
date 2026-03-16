// Screen: ProfilePage
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../core/theme/app_colors.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_bio.dart';
import '../widgets/profile/photo_gallery.dart';
import '../widgets/profile/profile_info_sections.dart';
import '../widgets/profile/profile_action_buttons.dart';
import '../widgets/profile/safety_verification_section.dart';
import '../core/widgets/loading_indicator.dart';
import '../core/widgets/profile_stats_card.dart';
import '../widgets/error_handling/error_display_widget.dart';
import '../widgets/loading/skeleton_profile.dart';
import '../widgets/match/match_screen.dart';
import '../features/profile/providers/profile_page_cache_provider.dart';
import '../features/profile/providers/profile_providers.dart';
import '../features/profile/providers/profile_provider.dart';
import '../features/profile/data/models/user_image.dart';
import '../features/profile/data/models/user_profile.dart';
import '../features/matching/providers/likes_providers.dart';
import '../features/safety/providers/user_actions_providers.dart';
import '../features/safety/data/models/block.dart';
import '../features/safety/data/models/report.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import '../pages/profile_edit_page.dart';
import '../screens/settings_screen.dart';
import '../core/utils/app_icons.dart';
import '../features/safety/data/models/favorite.dart';
import '../features/safety/presentation/screens/report_user_screen.dart';
import 'package:go_router/go_router.dart';

/// Profile page - Displays user's own profile
class ProfilePage extends ConsumerStatefulWidget {
  final int? userId; // If null, shows current user's profile

  const ProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  UserProfile? _profile;
  int _matchesCount = 0;
  int _pendingLikesCount = 0;
  /// Badge info from GET profile/badge/info (own profile only).
  Map<String, dynamic>? _badgeInfo;

  @override
  void initState() {
    super.initState();
    if (_isOwnProfile) {
      _loadStatistics();
      _loadBadgeInfo();
      // Cache-first: render from cache immediately; refresh in background (no blocking).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profilePageCacheProvider.notifier).refresh();
        _loadBadgeInfo();
      });
    } else {
      _loadProfile();
    }
  }

  /// Load badge info from GET profile/badge/info for own profile header.
  Future<void> _loadBadgeInfo() async {
    if (!_isOwnProfile) return;
    try {
      final info = await ref.read(profileServiceProvider).getProfileBadgeInfo();
      if (mounted) setState(() => _badgeInfo = info);
    } catch (_) {
      // Non-blocking; header falls back to profile flags
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final profileService = ref.read(profileServiceProvider);
      
      final profile = widget.userId == null
          ? await profileService.getMyProfile()
          : await profileService.getUserProfile(widget.userId!);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (kDebugMode) {
        debugPrint('[PROFILE] _loadProfile ApiError: ${e.message}');
        debugPrint('[PROFILE] ApiError code: ${e.code}');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[PROFILE] _loadProfile exception: $e');
        debugPrint('[PROFILE] stack: $stack');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStatistics() async {
    if (!_isOwnProfile) return;
    
    try {
      final likesService = ref.read(likesServiceProvider);
      
      // Load matches and pending likes in parallel
      final results = await Future.wait([
        likesService.getMatches(),
        likesService.getPendingLikes(),
      ]);

      if (mounted) {
        setState(() {
          _matchesCount = results[0].length;
          _pendingLikesCount = results[1].length;
        });
      }
    } catch (e) {
      // Silently fail - statistics are not critical
    }
  }

  int? _calculateAge([UserProfile? p]) {
    final pr = p ?? _profile;
    if (pr?.birthDate == null) return null;
    try {
      final birthDate = DateTime.parse(pr!.birthDate!);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  String _getLocation([UserProfile? p]) {
    final pr = p ?? _profile;
    final parts = <String>[];
    if (pr?.city != null) parts.add(pr!.city!);
    if (pr?.country != null) parts.add(pr!.country!);
    return parts.isEmpty ? 'Location not set' : parts.join(', ');
  }

  String _getFullName([UserProfile? p]) {
    final pr = p ?? _profile;
    if (pr == null) return '';
    return pr.lastName != null
        ? '${pr.firstName} ${pr.lastName}'
        : pr.firstName;
  }

  Future<void> _handleLike() async {
    if (widget.userId == null) return;
    
    try {
      final likesService = ref.read(likesServiceProvider);
      final response = await likesService.likeUser(widget.userId!);
      
      if (mounted) {
        if (response.isMatch) {
          // Show match dialog
          _showMatchDialog(response.match);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Like sent!'),
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
    if (widget.userId == null) return;
    
    try {
      final likesService = ref.read(likesServiceProvider);
      final response = await likesService.superlikeUser(widget.userId!);
      
      if (mounted) {
        if (response.isMatch) {
          // Show match dialog
          _showMatchDialog(response.match);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Superlike sent!'),
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

  void _showMatchDialog(dynamic match) {
    // Navigate to match screen
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MatchScreen(
          match: match,
          onSendMessage: () {
            Navigator.pop(context); // Close match screen
            // Navigate to chat
            context.push('/chat/${match.userId}');
          },
          onKeepSwiping: () {
            Navigator.pop(context); // Close match screen
            // Navigate back to discovery
            context.go('/discover');
          },
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    if (widget.userId == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: AppSvgIcon(
                  assetPath: AppIcons.block,
                  color: AppColors.accentRed,
                  size: 24,
                ),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockConfirmation(context);
                },
              ),
              ListTile(
                leading: AppSvgIcon(
                  assetPath: AppIcons.flag,
                  color: AppColors.warningYellow,
                  size: 24,
                ),
                title: const Text('Report User'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(context);
                },
              ),
              ListTile(
                leading: AppSvgIcon(
                  assetPath: AppIcons.favoriteBorder,
                  color: AppColors.accentPurple,
                  size: 24,
                ),
                title: const Text('Add to Favorites'),
                onTap: () {
                  Navigator.pop(context);
                  _addToFavorites();
                },
              ),
              ListTile(
                leading: AppSvgIcon(
                  assetPath: AppIcons.bellSlash,
                  color: AppColors.textSecondaryLight,
                  size: 24,
                ),
                title: const Text('Mute User'),
                onTap: () {
                  Navigator.pop(context);
                  _muteUser();
                },
              ),
              const Divider(),
              ListTile(
                leading: AppSvgIcon(
                  assetPath: AppIcons.close,
                  size: 24,
                ),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBlockConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${_getFullName()}? You won\'t see each other anymore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.userId != null) {
      try {
        final userActionsService = ref.read(userActionsServiceProvider);
        await userActionsService.blockUser(
          BlockUserRequest(blockedUserId: widget.userId!),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User blocked successfully'),
              backgroundColor: AppColors.onlineGreen,
            ),
          );
          // Navigate back
          Navigator.pop(context);
        }
      } on ApiError catch (e) {
        if (mounted) {
          ErrorHandlerService.showErrorSnackBar(
            context,
            e,
            customMessage: 'Failed to block user',
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorHandlerService.handleError(
            context,
            e,
            customMessage: 'Failed to block user',
          );
        }
      }
    }
  }

  Future<void> _showReportDialog(BuildContext context) async {
    // Navigate to report screen
    if (widget.userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportUserScreen(userId: widget.userId!),
        ),
      );
    }
  }

  Future<void> _addToFavorites() async {
    if (widget.userId == null) return;
    
    try {
      final userActionsService = ref.read(userActionsServiceProvider);
      await userActionsService.addToFavorites(
        AddFavoriteRequest(favoriteUserId: widget.userId!),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to favorites'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to add to favorites',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to add to favorites',
        );
      }
    }
  }

  Future<void> _muteUser() async {
    if (widget.userId == null) return;
    
    try {
      final userActionsService = ref.read(userActionsServiceProvider);
      await userActionsService.muteUser(widget.userId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User muted'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to mute user',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to mute user',
        );
      }
    }
  }

  List<String> _getImageUrls([UserProfile? p]) {
    final pr = p ?? _profile;
    if (pr?.images == null || pr!.images!.isEmpty) {
      return [];
    }
    return pr.images!.map((img) => img.imageUrl).toList();
  }

  bool get _isOwnProfile => widget.userId == null;

  /// Resolve verified from GET profile/badge/info or profile (own profile only).
  bool _badgeVerified(UserProfile? profile) {
    if (_badgeInfo != null) {
      final inner = (_badgeInfo!['data'] as Map<String, dynamic>?) ?? _badgeInfo!;
      final v = inner['verified'] ?? inner['is_verified'];
      if (v != null) return v == true || v == 1;
    }
    return profile?.isVerified ?? false;
  }

  /// Resolve premium from GET profile/badge/info or profile (own profile only).
  bool _badgePremium(UserProfile? profile) {
    if (_badgeInfo != null) {
      final inner = (_badgeInfo!['data'] as Map<String, dynamic>?) ?? _badgeInfo!;
      final p = inner['is_premium'] ?? inner['premium'];
      if (p != null) return p == true || p == 1;
    }
    return profile?.isPremium ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final isOwn = _isOwnProfile;
    final cacheState = isOwn ? ref.watch(profilePageCacheProvider) : null;
    final bool loading = isOwn
        ? (cacheState!.isLoading && !cacheState.hasValue)
        : _isLoading;
    final bool hasError = isOwn
        ? (cacheState!.hasError && !cacheState.hasValue)
        : _hasError;
    final UserProfile? profile = isOwn
        ? cacheState?.valueOrNull?.profile
        : _profile;
    final VoidCallback? onRetry = isOwn
        ? () => ref.read(profilePageCacheProvider.notifier).refresh()
        : () { _loadProfile(); };

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: isOwn ? 'My Profile' : 'Profile',
        showBackButton: !isOwn,
        showPrideAccent: isOwn,
        actions: isOwn
            ? [
                IconButton(
                  icon: AppSvgIcon(
                    assetPath: AppIcons.edit,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileEditPage(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: AppSvgIcon(
                    assetPath: AppIcons.settings,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    size: 24,
                  ),
                  onPressed: () {
                    // Navigate to settings screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: loading
          ? SkeletonProfile()
          : hasError
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage ?? 'Failed to load profile',
                  onRetry: onRetry ?? () {},
                )
              : profile == null
                  ? const Center(child: Text('No profile data'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        if (isOwn) {
                          await ref.read(profilePageCacheProvider.notifier).refresh();
                          await _loadStatistics();
                          await _loadBadgeInfo();
                        } else {
                          await _loadProfile();
                        }
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileHeader(
                            name: _getFullName(profile),
                            age: _calculateAge(profile),
                            location: _getLocation(profile),
                            avatarUrl: _getImageUrls(profile).isNotEmpty ? _getImageUrls(profile).first : null,
                            isVerified: _badgeVerified(profile),
                            isPremium: _badgePremium(profile),
                            isOnline: profile?.isOnline ?? false,
                            showPrideAccent: isOwn,
                            onAvatarTap: isOwn
                                ? () {
                                    // Open image picker - implementation needed
                                    _openImagePicker();
                                  }
                                : null,
                            onEdit: isOwn
                                ? () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ProfileEditPage(),
                                      ),
                                    );
                                    if (isOwn) {
                                      ref.read(profilePageCacheProvider.notifier).refresh();
                                      _loadStatistics();
                                    } else {
                                      _loadProfile();
                                    }
                                  }
                                : null,
                          ),
                          // Statistics (only for own profile)
                          if (isOwn)
                            ProfileStatsCard(
                              matchesCount: _matchesCount,
                              likesCount: _pendingLikesCount,
                              viewsCount: profile?.viewsCount ?? 0,
                            ),
                          ProfileBio(
                            bio: profile!.profileBio,
                            isEditable: isOwn,
                            onEdit: isOwn
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ProfileEditPage(),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                          if (_getImageUrls(profile).isNotEmpty)
                            PhotoGallery(
                              imageUrls: _getImageUrls(profile),
                              isEditable: isOwn,
                              onImageTap: (index, url) {
                                // Open image viewer - implementation needed
                                _openImageViewer(index);
                              },
                              onAddPhoto: isOwn
                                  ? () => _openImagePicker()
                                  : null,
                            ),
                          ProfileInfoSections(
                            interests: profile!.interests != null
                                ? profile!.interests!.map((id) => id.toString()).toList()
                                : [],
                            jobs: profile!.jobs != null
                                ? profile!.jobs!.map((id) => id.toString()).toList()
                                : [],
                            educations: profile!.educations != null
                                ? profile!.educations!.map((id) => id.toString()).toList()
                                : [],
                            languages: profile!.languages != null
                                ? profile!.languages!.map((id) => id.toString()).toList()
                                : [],
                            musicGenres: profile!.musicGenres != null
                                ? profile!.musicGenres!.map((id) => id.toString()).toList()
                                : [],
                            relationGoals: profile!.relationGoals != null
                                ? profile!.relationGoals!.map((id) => id.toString()).toList()
                                : [],
                            gender: profile!.gender,
                            preferredGenders: profile!.preferredGenders != null
                                ? profile!.preferredGenders!.map((id) => id.toString()).toList()
                                : [],
                            height: profile!.height,
                            weight: profile!.weight,
                            smoke: profile!.smoke,
                            drink: profile!.drink,
                            gym: profile!.gym,
                          ),
                          if (isOwn)
                            SafetyVerificationSection(
                              isVerified: profile?.isVerified ?? false,
                              isPhoneVerified: profile?.isPhoneVerified ?? false,
                              isEmailVerified: profile?.isEmailVerified ?? true,
                              onVerifyTap: () {
                                // Navigate to verification
                                context.go('/profile/verification');
                              },
                            ),
                          if (!isOwn)
                            ProfileActionButtons(
                              onLike: () {
                                _handleLike();
                              },
                              onSuperlike: () {
                                _handleSuperlike();
                              },
                              onMessage: () {
                                if (widget.userId != null) {
                                  context.go('/chat?userId=${widget.userId}');
                                }
                              },
                              onMore: () {
                                _showMoreOptions(context);
                              },
                              isLiked: false,
                              isSuperliked: false,
                              isMatched: false,
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                      ),
                    ),
    );
  }

  Future<void> _openImagePicker() async {
    final ImagePicker picker = ImagePicker();

    // Show bottom sheet with options
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1920,
                      maxHeight: 1080,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      await _handlePickedImage(File(image.path));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error taking photo: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1920,
                      maxHeight: 1080,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      await _handlePickedImage(File(image.path));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error selecting image: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePickedImage(File imageFile) async {
    try {
      // Upload image using profile provider
      final profileNotifier = ref.read(profileProvider.notifier);
      await profileNotifier.uploadImage(imageFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image uploaded successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Here you would typically:
    // 1. Upload the image to backend
    // 2. Get the image URL from response
    // 3. Update the profile with new image URL
    // 4. Refresh the profile data
  }

  void _openImageViewer(int initialIndex) {
    final imageUrls = _getImageUrls();

    if (imageUrls.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: PhotoViewGallery.builder(
            itemCount: imageUrls.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imageUrls[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: 'profile_image_$index',
                ),
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
            pageController: PageController(initialPage: initialIndex),
            onPageChanged: (index) {
              // Optional: Update current page indicator
            },
            loadingBuilder: (context, event) => Center(
              child: SizedBox(
                width: 30.0,
                height: 30.0,
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
