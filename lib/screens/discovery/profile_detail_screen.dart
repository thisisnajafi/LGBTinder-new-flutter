// Screen: ProfileDetailScreen — other user's profile (messenger, chat, discovery)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../features/profile/data/models/user_profile.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../features/profile/widgets/profile_photo_carousel.dart';
import '../../features/profile/widgets/tier_badge.dart';
import '../../features/reference_data/providers/reference_data_providers.dart';
import '../../features/safety/presentation/screens/report_user_screen.dart';
import '../../features/safety/providers/user_actions_providers.dart';
import '../../features/safety/data/models/block.dart';
import '../../features/safety/data/models/favorite.dart';
import '../../routes/app_router.dart';
import '../../shared/models/api_error.dart';
import '../../shared/providers/user_tier_provider.dart';
import '../../shared/services/error_handler_service.dart';
import '../../widgets/error_handling/error_display_widget.dart';
import '../../widgets/profile/profile_bio.dart';
import '../../widgets/profile/profile_info_sections.dart';
import '../../widgets/profile/profile_action_buttons.dart';
import '../../core/cache/cache_manager.dart' show notifyNewMatch;
import '../../features/matching/providers/likes_providers.dart';
import '../../features/matching/providers/matching_provider.dart';
import '../../features/matching/data/models/match.dart' as match_models;
import '../../widgets/match/match_screen.dart';

class ProfileDetailScreen extends ConsumerStatefulWidget {
  final int userId;

  /// When true, shows discovery swipe actions (like / pass / superlike).
  /// Defaults to false for messenger and chat profile views.
  final bool showInteractionActions;

  const ProfileDetailScreen({
    super.key,
    required this.userId,
    this.showInteractionActions = false,
  });

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
      var isMatched = false;
      if (widget.showInteractionActions) {
        isMatched =
            await ref.read(matchingProvider.notifier).checkMatchStatus(widget.userId);
      }

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

  String _userFriendlyProfileError(ApiError? e, {String? fallback}) {
    if (e != null) {
      if (e.code == 500 ||
          (e.message.contains('SQLSTATE') || e.message.contains("doesn't exist"))) {
        return "We're having trouble loading this profile. Please try again later.";
      }
      return e.message;
    }
    final msg = fallback ?? 'Something went wrong';
    if (msg.contains('SQLSTATE') ||
        msg.contains("doesn't exist") ||
        msg.contains('500')) {
      return "We're having trouble loading this profile. Please try again later.";
    }
    return msg;
  }

  Future<void> _handleLike() async {
    if (_profile == null) return;
    try {
      final likesService = ref.read(likesServiceProvider);
      final response = await likesService.likeUser(_profile!.id);
      if (mounted && response.isMatch) {
        await notifyNewMatch(ref);
        _showMatchDialog(response.match);
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
      if (mounted && response.isMatch) {
        await notifyNewMatch(ref);
        _showMatchDialog(response.match);
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
    context.push(
      Uri(
        path: AppRoutes.chat,
        queryParameters: {
          'userId': _profile!.id.toString(),
          'userName': _fullName(_profile!).trim(),
        },
      ).toString(),
    );
  }

  List<String>? _labelsFromProfile(
    List<String>? apiTitles,
    List<int>? ids,
    List<dynamic> refs,
  ) {
    if (apiTitles != null && apiTitles.isNotEmpty) return apiTitles;
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
        .map((id) => byId[id])
        .whereType<String>()
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return values.isEmpty ? null : values;
  }

  String? _genderLabel(UserProfile profile, List<dynamic> gendersRef) {
    if (profile.gender != null && profile.gender!.trim().isNotEmpty) {
      return profile.gender;
    }
    if (profile.genderId == null) return null;
    for (final item in gendersRef) {
      if (item.id == profile.genderId) return item.title as String?;
    }
    return null;
  }

  void _showMatchDialog(match_models.Match? match) {
    if (match == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.backgroundDark.withValues(alpha: 0.87),
      builder: (context) => MatchScreen(
        match: match,
        onSendMessage: () {
          Navigator.pop(context);
          _handleMessage();
        },
        onKeepSwiping: () => Navigator.pop(context),
      ),
    );
  }

  int? _calculateAge(UserProfile profile) {
    if (profile.birthDate == null) return null;
    try {
      final birthDate = DateTime.parse(profile.birthDate!);
      final now = DateTime.now();
      var age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  String _fullName(UserProfile profile) {
    return '${profile.firstName} ${profile.lastName}'.trim();
  }

  String _getLocation(UserProfile profile) {
    final parts = <String>[];
    if (profile.city != null && profile.city!.isNotEmpty) {
      parts.add(profile.city!);
    }
    if (profile.country != null && profile.country!.isNotEmpty) {
      parts.add(profile.country!);
    }
    return parts.isEmpty ? 'Location not set' : parts.join(', ');
  }

  List<String> _getImageUrls(UserProfile profile) {
    if (profile.images == null || profile.images!.isEmpty) return [];
    return profile.images!.map((img) => img.imageUrl).toList();
  }

  void _showMoreOptions() {
    showModalBottomSheet<void>(
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
                  _showBlockConfirmation();
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
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ReportUserScreen(userId: widget.userId),
                    ),
                  );
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
              const Divider(),
              ListTile(
                leading: AppSvgIcon(assetPath: AppIcons.close, size: 24),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBlockConfirmation() async {
    final profile = _profile;
    if (profile == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${_fullName(profile)}? '
          'You won\'t see each other anymore.',
        ),
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

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(userActionsServiceProvider).blockUser(
            BlockUserRequest(blockedUserId: widget.userId),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User blocked successfully'),
          backgroundColor: AppColors.onlineGreen,
        ),
      );
      Navigator.pop(context);
    } on ApiError catch (e) {
      if (!mounted) return;
      ErrorHandlerService.showErrorSnackBar(
        context,
        e,
        customMessage: 'Failed to block user',
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandlerService.handleError(
        context,
        e,
        customMessage: 'Failed to block user',
      );
    }
  }

  Future<void> _addToFavorites() async {
    try {
      await ref.read(userActionsServiceProvider).addToFavorites(
            AddFavoriteRequest(favoriteUserId: widget.userId),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to favorites'),
          backgroundColor: AppColors.onlineGreen,
        ),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      ErrorHandlerService.showErrorSnackBar(
        context,
        e,
        customMessage: 'Failed to add to favorites',
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandlerService.handleError(
        context,
        e,
        customMessage: 'Failed to add to favorites',
      );
    }
  }

  Widget _buildProfileContent(UserProfile profile) {
    final interestsRef = ref.watch(interestsProvider).valueOrNull ?? const [];
    final jobsRef = ref.watch(jobsProvider).valueOrNull ?? const [];
    final educationsRef = ref.watch(educationLevelsProvider).valueOrNull ?? const [];
    final languagesRef = ref.watch(languagesProvider).valueOrNull ?? const [];
    final preferredGendersRef =
        ref.watch(preferredGendersProvider).valueOrNull ?? const [];
    final relationGoalsRef =
        ref.watch(relationshipGoalsProvider).valueOrNull ?? const [];
    final musicRef = ref.watch(musicGenresProvider).valueOrNull ?? const [];
    final gendersRef = ref.watch(gendersProvider).valueOrNull ?? const [];
    final tier = profile.isPremium == true ? null : ref.watch(userTierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_getImageUrls(profile).isNotEmpty)
          RepaintBoundary(
            child: ProfilePhotoCarousel(
              imageUrls: _getImageUrls(profile),
              overlayHeader: ProfileOverlayHeader(
                name: _fullName(profile),
                age: _calculateAge(profile),
                isVerified: profile.isVerified ?? false,
                tier: tier,
                isPremiumFallback: profile.isPremium ?? false,
                location: _getLocation(profile),
              ),
            ),
          )
        else
          const ProfilePhotoEmptyState(),
        ProfileBio(bio: profile.profileBio),
        ProfileInfoSections(
          interests: _labelsFromProfile(
            profile.interestTitles,
            profile.interests,
            interestsRef,
          ),
          jobs: _labelsFromProfile(profile.jobTitles, profile.jobs, jobsRef),
          educations: _labelsFromProfile(
            profile.educationTitles,
            profile.educations,
            educationsRef,
          ),
          languages: _labelsFromProfile(null, profile.languages, languagesRef),
          musicGenres: _labelsFromProfile(null, profile.musicGenres, musicRef),
          relationGoals:
              _labelsFromProfile(null, profile.relationGoals, relationGoalsRef),
          gender: _genderLabel(profile, gendersRef),
          preferredGenders: _labelsFromProfile(
            null,
            profile.preferredGenders,
            preferredGendersRef,
          ),
          height: profile.height,
          weight: profile.weight,
          smoke: profile.smoke,
          drink: profile.drink,
          gym: profile.gym,
          location: _getLocation(profile),
        ),
        SizedBox(height: AppSpacing.spacingXXL),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final profile = _profile;
    final showActions = widget.showInteractionActions &&
        profile != null &&
        !_isLoading &&
        !_hasError;

    return AppPageScaffold(
      title: 'Profile',
      showBackButton: true,
      backgroundColor: backgroundColor,
      action: !widget.showInteractionActions && profile != null
          ? IconButton(
              icon: AppSvgIcon(
                assetPath: AppIcons.more,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: _showMoreOptions,
            )
          : null,
      bottomNavigationBar: showActions
          ? ProfileActionButtons(
              onLike: _handleLike,
              onDislike: () => Navigator.pop(context),
              onSuperlike: _handleSuperlike,
              onMessage: _handleMessage,
              isMatched: _isMatched,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage ?? 'Failed to load profile',
                  onRetry: _loadProfile,
                )
              : profile == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _loadProfile,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: _buildProfileContent(profile),
                      ),
                    ),
    );
  }
}
