// Screen: ProfileDetailScreen — other user's profile
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../widgets/profile/profile_bio.dart';
import '../../widgets/profile/profile_info_sections.dart';
import '../../widgets/profile/profile_action_buttons.dart';
import '../../widgets/error_handling/error_display_widget.dart';
import '../../features/profile/widgets/profile_photo_carousel.dart';
import '../../features/profile/widgets/tier_badge.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../features/profile/data/models/user_profile.dart';
import '../../features/reference_data/providers/reference_data_providers.dart';
import '../../features/matching/providers/likes_providers.dart';
import '../../features/matching/providers/matching_provider.dart';
import '../../features/matching/data/models/match.dart' as match_models;
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import '../../shared/providers/user_tier_provider.dart';
import '../../widgets/match/match_screen.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';
import '../../core/cache/cache_manager.dart' show notifyNewMatch;

class ProfileDetailScreen extends ConsumerStatefulWidget {
  final int userId;

  const ProfileDetailScreen({super.key, required this.userId});

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
      final isMatched = await ref.read(matchingProvider.notifier).checkMatchStatus(widget.userId);

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
      if (mounted && response.isMatch) {
        await notifyNewMatch(ref);
        _showMatchDialog(response.match as match_models.Match?);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(context, e, customMessage: 'Failed to like user');
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
        _showMatchDialog(response.match as match_models.Match?);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(context, e, customMessage: 'Failed to superlike user');
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
          'userName': '${_profile!.firstName} ${_profile!.lastName}'.trim(),
        },
      ).toString(),
    );
  }

  List<String>? _mapIdsToTitles(List<int>? ids, List<dynamic> refs) {
    if (ids == null || ids.isEmpty) return null;
    final byId = <int, String>{};
    for (final item in refs) {
      final id = item.id as int?;
      final title = item.title as String?;
      if (id != null && title != null && title.isNotEmpty) byId[id] = title;
    }
    final values = ids.map((id) => byId[id] ?? id.toString()).toSet().toList(growable: false);
    return values.isEmpty ? null : values;
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
    } catch (_) {
      return null;
    }
  }

  String _getLocation() {
    final parts = <String>[];
    if (_profile?.city != null && _profile!.city!.isNotEmpty) parts.add(_profile!.city!);
    if (_profile?.country != null && _profile!.country!.isNotEmpty) parts.add(_profile!.country!);
    return parts.isEmpty ? 'Location not set' : parts.join(', ');
  }

  List<String> _getImageUrls() {
    if (_profile?.images == null || _profile!.images!.isEmpty) return [];
    return _profile!.images!.map((img) => img.imageUrl).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final interestsRef = ref.watch(interestsProvider).valueOrNull ?? const [];
    final jobsRef = ref.watch(jobsProvider).valueOrNull ?? const [];
    final educationsRef = ref.watch(educationLevelsProvider).valueOrNull ?? const [];
    final languagesRef = ref.watch(languagesProvider).valueOrNull ?? const [];
    final preferredGendersRef = ref.watch(preferredGendersProvider).valueOrNull ?? const [];
    final relationGoalsRef = ref.watch(relationshipGoalsProvider).valueOrNull ?? const [];
    final tier = _profile?.isPremium == true ? null : ref.watch(userTierProvider);

    return AppPageScaffold(
      title: 'Profile',
      showBackButton: true,
      backgroundColor: backgroundColor,
      bottomNavigationBar: _profile != null && !_isLoading && !_hasError
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
              : _profile == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_getImageUrls().isNotEmpty)
                            ProfilePhotoCarousel(
                              imageUrls: _getImageUrls(),
                              overlayHeader: ProfileOverlayHeader(
                                name: '${_profile!.firstName} ${_profile!.lastName}'.trim(),
                                age: _calculateAge(),
                                isVerified: _profile!.isVerified ?? false,
                                tier: tier,
                                isPremiumFallback: _profile!.isPremium ?? false,
                                location: _getLocation(),
                              ),
                            )
                          else
                            const ProfilePhotoEmptyState(),
                          if (_profile!.profileBio != null && _profile!.profileBio!.isNotEmpty)
                            ProfileBio(bio: _profile!.profileBio),
                          ProfileInfoSections(
                            interests: _mapIdsToTitles(_profile!.interests, interestsRef),
                            jobs: _mapIdsToTitles(_profile!.jobs, jobsRef),
                            educations: _mapIdsToTitles(_profile!.educations, educationsRef),
                            languages: _mapIdsToTitles(_profile!.languages, languagesRef),
                            gender: _profile!.gender,
                            preferredGenders:
                                _mapIdsToTitles(_profile!.preferredGenders, preferredGendersRef),
                            relationGoals:
                                _mapIdsToTitles(_profile!.relationGoals, relationGoalsRef),
                            height: _profile!.height,
                            weight: _profile!.weight,
                            smoke: _profile!.smoke,
                            drink: _profile!.drink,
                            gym: _profile!.gym,
                            location: _getLocation(),
                          ),
                          SizedBox(height: AppSpacing.spacingXXL),
                        ],
                      ),
                    ),
    );
  }
}
