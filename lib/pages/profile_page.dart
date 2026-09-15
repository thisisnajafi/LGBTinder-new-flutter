// Screen: ProfilePage
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../core/theme/app_colors.dart';
import '../core/responsive/responsive.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../features/profile/presentation/widgets/own_profile/own_profile_view.dart';
import '../features/profile/presentation/widgets/own_profile/profile_photo_utils.dart';
import '../features/reference_data/providers/reference_data_providers.dart';
import '../widgets/error_handling/error_display_widget.dart';
import '../widgets/loading/skeleton_profile.dart';
import '../features/matching/data/models/match.dart' as match_models;
import '../features/matching/widgets/match_celebration_launcher.dart';
import '../core/utils/app_media_picker.dart';
import '../core/constants/app_constants.dart';
import '../core/cache/cache_invalidator.dart';
import '../core/cache/cache_manager.dart' show notifyNewMatch;
import '../core/cache/image_cache_service.dart';
import '../features/profile/providers/profile_page_cache_provider.dart'
    show ProfilePageData, profilePageCacheProvider;
import '../features/profile/providers/profile_providers.dart';
import '../features/profile/data/models/user_profile.dart';
import '../features/matching/providers/likes_providers.dart';
import '../features/safety/providers/user_actions_providers.dart';
import '../features/safety/data/models/block.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import '../routes/app_router.dart';
import '../core/utils/app_icons.dart';
import '../features/profile/presentation/widgets/other_user_profile/other_user_profile_view.dart';
import '../features/profile/presentation/widgets/other_user_profile/profile_more_options_sheet.dart';
import '../widgets/profile/profile_photo_source_sheet.dart';
import '../core/utils/app_logger.dart';
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

  @override
  void initState() {
    super.initState();
    // Own profile is served only by [profilePageCacheProvider] (PERF-PAGE-PROFILE-001).
    if (!_isOwnProfile) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final otherUserId = widget.userId;
    if (otherUserId == null) {
      await ref.read(profilePageCacheProvider.notifier).refresh();
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final profile =
          await ref.read(profileServiceProvider).getUserProfile(otherUserId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      AppLogger.warning(
        'Other-user profile load failed',
        tag: 'Profile',
        error: e,
      );
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error(
        'Other-user profile load exception',
        tag: 'Profile',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getFullName([UserProfile? p]) {
    final pr = p ?? _profile;
    if (pr == null) return '';
    return pr.lastName.trim().isEmpty
        ? pr.firstName
        : '${pr.firstName} ${pr.lastName}';
  }

  Future<void> _handleLike() async {
    if (widget.userId == null) return;
    
    try {
      final likesService = ref.read(likesServiceProvider);
      final response = await likesService.likeUser(widget.userId!);
      
      if (mounted) {
        if (response.isMatch) {
          unawaited(notifyNewMatch(ref));
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
          unawaited(notifyNewMatch(ref));
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
    if (match is! match_models.Match) return;
    unawaited(MatchCelebrationLauncher.show(context, ref, match: match));
  }

  void _showMoreOptions(BuildContext context) {
    if (widget.userId == null) return;

    ProfileMoreOptionsSheet.show(
      context,
      userName: _getFullName(),
      onBlock: () => _showBlockConfirmation(context),
      onReport: () => _showReportDialog(context),
      onAddFavorite: _addToFavorites,
      onMute: _muteUser,
    );
  }

  Future<void> _showBlockConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveGrid.constrainedTo(
        context,
        AlertDialog(
          title: const AppText(
            'Block User',
            maxLines: 1,
          ),
          content: AppText(
            'Are you sure you want to block ${_getFullName()}? You won\'t see each other anymore.',
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const AppText(
                'Cancel',
                maxLines: 1,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
              child: const AppText(
                'Block',
                maxLines: 1,
              ),
            ),
          ],
        ),
        tablet: 400,
      ),
    );

    if (confirmed == true && widget.userId != null) {
      try {
        final userActionsService = ref.read(userActionsServiceProvider);
        await userActionsService.blockUser(
          BlockUserRequest(blockedUserId: widget.userId!),
        );
        await ref
            .read(cacheInvalidatorProvider)
            .purgeProfile(widget.userId!.toString());

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

  Future<void> _openProfileEdit() async {
    await context.push(AppRoutes.profileEdit);
    if (mounted) {
      await ref.read(profilePageCacheProvider.notifier).refresh();
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

  String _formatProfileCacheError(AsyncValue<ProfilePageData> cacheState) {
    final error = cacheState.error;
    final stack = cacheState.stackTrace;
    if (error != null) {
      profileLogError('ProfilePage UI error state', error, stack);
    }
    if (error is ApiError) {
      return error.message;
    }
    if (error != null) {
      final text = error.toString();
      if (text.contains('SocketException') || text.contains('Connection')) {
        return 'Could not reach the server. Check your connection and try again.';
      }
      if (kDebugMode) {
        return 'Could not load your profile ($text). Tap retry.';
      }
      return 'Could not load your profile. Tap retry to try again.';
    }
    return 'Could not load your profile. Tap retry to try again.';
  }

  void _openFullProfileView(UserProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PremiumDetailScaffold(
          title: 'My Profile',
          onBack: () => Navigator.pop(context),
          action: IconButton(
            icon: AppSvgIcon(
              assetPath: AppIcons.edit,
              size: 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _openProfileEdit,
          ),
          body: OwnProfileView(
            profile: profile,
            onViewProfile: () {},
            onEditPhotos: _openProfileEdit,
            onAddPhoto: _openImagePicker,
            onPhotoTap: _openImageViewer,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = _isOwnProfile;
    final cacheState = isOwn ? ref.watch(profilePageCacheProvider) : null;

    final bool loading = isOwn
        ? (cacheState!.isLoading && !cacheState.hasValue)
        : _isLoading;
    final bool hasError = isOwn
        ? (cacheState!.hasError && !cacheState.hasValue)
        : _hasError;

    if (isOwn && cacheState != null && kDebugMode) {
      profileLog(
        'ProfilePage build: loading=$loading hasError=$hasError '
        'hasValue=${cacheState.hasValue} profileId=${cacheState.valueOrNull?.profile.id}',
      );
    }
    final UserProfile? profile = isOwn
        ? cacheState?.valueOrNull?.profile
        : _profile;
    final VoidCallback? onRetry = isOwn
        ? () {
            profileLog('ProfilePage: user tapped Retry');
            ref.read(profilePageCacheProvider.notifier).refresh();
          }
        : () {
            profileLog('ProfilePage: user tapped Retry (other user)');
            _loadProfile();
          };
    final String? ownProfileErrorMessage = isOwn && cacheState != null
        ? _formatProfileCacheError(cacheState)
        : null;

    Widget bodyContent;
    if (loading) {
      bodyContent = const SkeletonProfile();
    } else if (hasError) {
      bodyContent = ErrorDisplayWidget(
        errorMessage: ownProfileErrorMessage ??
            _errorMessage ??
            'Failed to load profile. Pull to retry.',
        onRetry: onRetry ?? () {},
      );
    } else if (profile == null) {
      bodyContent = const Center(child: Text('No profile data'));
    } else if (isOwn) {
      bodyContent = OwnProfileView(
        profile: profile,
        onViewProfile: () => _openFullProfileView(profile),
        onEditPhotos: _openProfileEdit,
        onAddPhoto: _openImagePicker,
        onPhotoTap: _openImageViewer,
      );
    } else {
      final interestsRef = ref.watch(interestsProvider).valueOrNull ?? const [];
      final jobsRef = ref.watch(jobsProvider).valueOrNull ?? const [];
      final educationsRef =
          ref.watch(educationLevelsProvider).valueOrNull ?? const [];
      final languagesRef = ref.watch(languagesProvider).valueOrNull ?? const [];
      final preferredGendersRef =
          ref.watch(preferredGendersProvider).valueOrNull ?? const [];
      final relationGoalsRef =
          ref.watch(relationshipGoalsProvider).valueOrNull ?? const [];
      final musicRef = ref.watch(musicGenresProvider).valueOrNull ?? const [];
      final gendersRef = ref.watch(gendersProvider).valueOrNull ?? const [];

      bodyContent = OtherUserProfileView(
        profile: profile,
        locationLabel: profileLocationLabel(profile),
        genderLabel: profileGenderLabel(profile, gendersRef),
        interestLabels: profileLabelsFromRefs(
          apiTitles: profile.interestTitles,
          ids: profile.interests,
          refs: interestsRef,
        ),
        jobLabels: profileLabelsFromRefs(
          apiTitles: profile.jobTitles,
          ids: profile.jobs,
          refs: jobsRef,
        ),
        educationLabels: profileLabelsFromRefs(
          apiTitles: profile.educationTitles,
          ids: profile.educations,
          refs: educationsRef,
        ),
        languageLabels: profileLabelsFromRefs(
          ids: profile.languages,
          refs: languagesRef,
        ),
        musicLabels: profileLabelsFromRefs(
          ids: profile.musicGenres,
          refs: musicRef,
        ),
        relationGoalLabels: profileLabelsFromRefs(
          ids: profile.relationGoals,
          refs: relationGoalsRef,
        ),
        preferredGenderLabels: profileLabelsFromRefs(
          ids: profile.preferredGenders,
          refs: preferredGendersRef,
        ),
        onMessage: widget.userId != null
            ? () {
                context.push(
                  Uri(
                    path: AppRoutes.chat,
                    queryParameters: {
                      'userId': widget.userId.toString(),
                      if (_getFullName(profile).trim().isNotEmpty)
                        'userName': _getFullName(profile).trim(),
                    },
                  ).toString(),
                );
              }
            : null,
        onLike: _handleLike,
        onSuperlike: _handleSuperlike,
        onMoreOptions: () => _showMoreOptions(context),
        onRefresh: _loadProfile,
        onPhotoTap: (index) => _openImageViewer(index),
      );
    }

    return PremiumTabPageLayout(
      title: 'Profile',
      subtitle: isOwn ? 'Your photos, bio, and membership' : 'Member profile',
      showTitleHeader: false,
      body: loading || hasError || profile == null
          ? bodyContent
          : PremiumRefreshIndicator(
              onRefresh: () async {
                if (isOwn) {
                  await ref.read(profilePageCacheProvider.notifier).refresh();
                } else {
                  await _loadProfile();
                }
              },
              child: bodyContent,
            ),
    );
  }

  Future<void> _openImagePicker() async {
    await ProfilePhotoSourceSheet.show(
      context,
      title: 'Add photo',
      onSourceSelected: (source) async {
        try {
          final image = await AppMediaPicker.pickImage(source: source);
          if (image != null) {
            await _handlePickedImage(File(image.path));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  source == ImageSource.camera
                      ? 'Error taking photo: $e'
                      : 'Error selecting image: $e',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _handlePickedImage(File imageFile) async {
    final cachedProfile = ref.read(profilePageCacheProvider).valueOrNull?.profile;
    final images = cachedProfile?.images ?? [];
    final galleryCount =
        images.where((image) => image.type == 'gallery').length;

    if (galleryCount >= AppConstants.maxGalleryPhotos ||
        images.length >= AppConstants.maxTotalProfilePhotos) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You can add up to ${AppConstants.maxGalleryPhotos} gallery photos '
              '(${AppConstants.maxTotalProfilePhotos} total including primary).',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final imageService = ref.read(imageServiceProvider);
      await imageService.uploadImage(imageFile, type: 'gallery');
      await ref.read(profilePageCacheProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gallery photo added successfully'),
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openImageViewer(int initialIndex) {
    final ownProfile =
        _isOwnProfile ? ref.read(profilePageCacheProvider).valueOrNull?.profile : null;
    final imageUrls = _isOwnProfile
        ? galleryProfileImages(ownProfile?.images)
            .map((img) => img.imageUrl)
            .toList()
        : _getImageUrls();

    if (imageUrls.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: AppSvgIcon(
                assetPath: AppIcons.close,
                size: 24,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: PhotoViewGallery.builder(
            itemCount: imageUrls.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: lgbtfinderCachedImageProvider(imageUrls[index]),
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
                  value: event == null ||
                          event.expectedTotalBytes == null ||
                          event.expectedTotalBytes! <= 0
                      ? null
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
