// Screen: ProfileDetailScreen — other user's profile (messenger, chat, discovery)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/profile/data/models/user_profile.dart';
import '../../features/profile/presentation/widgets/other_user_profile/other_user_profile_view.dart';
import '../../features/profile/presentation/widgets/other_user_profile/profile_more_options_sheet.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../features/reference_data/providers/reference_data_providers.dart';
import '../../features/safety/presentation/screens/report_user_screen.dart';
import '../../features/safety/presentation/widgets/block_user_dialog.dart';
import '../../features/safety/providers/user_actions_providers.dart';
import '../../features/safety/data/models/favorite.dart';
import '../../routes/app_router.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import '../../widgets/error_handling/error_display_widget.dart';
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
  ConsumerState<ProfileDetailScreen> createState() =>
      _ProfileDetailScreenState();
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

  String _fullName(UserProfile profile) {
    return '${profile.firstName} ${profile.lastName}'.trim();
  }

  void _showMoreOptions() {
    final profile = _profile;
    if (profile == null) return;

    ProfileMoreOptionsSheet.show(
      context,
      userName: _fullName(profile),
      onBlock: _openBlockDialog,
      onReport: _openReportScreen,
      onAddFavorite: _addToFavorites,
    );
  }

  void _openReportScreen() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ReportUserScreen(userId: widget.userId),
      ),
    );
  }

  Future<void> _openBlockDialog() async {
    final profile = _profile;
    if (profile == null) return;

    final avatar = profile.images != null && profile.images!.isNotEmpty
        ? profile.images!.first.imageUrl
        : null;

    await showDialog<void>(
      context: context,
      builder: (context) => BlockUserDialog(
        userId: widget.userId,
        userName: _fullName(profile),
        userAvatar: avatar,
        onBlockSuccess: () {
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _addToFavorites() async {
    try {
      await ref.read(userActionsServiceProvider).addToFavorites(
            AddFavoriteRequest(favoriteUserId: widget.userId),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Added to favorites'),
          backgroundColor: AppColors.feedbackSuccess,
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

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final showActions = widget.showInteractionActions &&
        profile != null &&
        !_isLoading &&
        !_hasError;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => Navigator.maybePop(context)),
        ),
        body: ErrorDisplayWidget(
          errorMessage: _errorMessage ?? 'Failed to load profile',
          onRetry: _loadProfile,
        ),
      );
    }

    if (profile == null) {
      return const SizedBox.shrink();
    }

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: showActions
          ? ProfileActionButtons(
              onLike: _handleLike,
              onDislike: () => Navigator.pop(context),
              onSuperlike: _handleSuperlike,
              onMessage: _handleMessage,
              isMatched: _isMatched,
            )
          : null,
      body: OtherUserProfileView(
          profile: profile,
          showInteractionActions: widget.showInteractionActions,
          isMatched: _isMatched,
          onMessage: _handleMessage,
          onMoreOptions: _showMoreOptions,
          onRefresh: _loadProfile,
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
        ),
    );
  }
}
