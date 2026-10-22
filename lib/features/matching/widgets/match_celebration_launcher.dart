import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_router.dart';
import '../../profile/data/models/user_profile.dart';
import '../../user/data/models/user_info.dart';
import '../../user/providers/user_providers.dart';
import '../data/models/match.dart' as match_models;
import '../pages/match_found_page.dart';

/// Dedupes the match celebration across every source (local swipe result,
/// Pusher `new_match`, FCM). Keys by match id AND by peer user id, because the
/// local swipe result can carry a fallback/zero match id while the realtime
/// event carries the server id for the same peer.
class MatchCelebrationDedupe {
  MatchCelebrationDedupe._();

  static const Duration window = Duration(seconds: 30);

  static final Map<int, DateTime> _byMatchId = <int, DateTime>{};
  static final Map<int, DateTime> _byPeerId = <int, DateTime>{};

  /// True while a celebration route is on screen (or being pushed).
  static bool isActive = false;
  static int? activePeerUserId;
  static int? activeMatchId;

  static bool _fresh(DateTime? at) =>
      at != null && DateTime.now().difference(at) < window;

  static void mark(int? matchId, int? userId) {
    final now = DateTime.now();
    if (matchId != null && matchId > 0) _byMatchId[matchId] = now;
    if (userId != null && userId > 0) _byPeerId[userId] = now;
    _prune();
  }

  static bool wasRecentlyShown(int? matchId, int? userId) {
    if (matchId != null && matchId > 0 && _fresh(_byMatchId[matchId])) {
      return true;
    }
    if (userId != null && userId > 0 && _fresh(_byPeerId[userId])) {
      return true;
    }
    return false;
  }

  /// Whether an in-app banner / heads-up for this match should be hidden
  /// (overlay open, or celebration already shown for this match/peer).
  static bool shouldSuppressBanner({int? matchId, int? peerUserId}) {
    if (isActive) return true;
    return wasRecentlyShown(matchId, peerUserId);
  }

  static void _prune() {
    _byMatchId.removeWhere((_, at) => !_fresh(at));
    _byPeerId.removeWhere((_, at) => !_fresh(at));
  }
}

/// Shows the premium match celebration overlay for a mutual match.
class MatchCelebrationLauncher {
  MatchCelebrationLauncher._();

  static final Set<String> _presented = <String>{};

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required match_models.Match match,
    String? matchedAvatarUrl,
  }) async {
    final userInfo = ref.read(cachedCurrentUserProvider).valueOrNull;
    if (userInfo != null && userInfo.id > 0 && match.userId == userInfo.id) {
      return;
    }
    // Re-entry guard: never stack a second overlay.
    if (MatchCelebrationDedupe.isActive) return;
    final peerKey = 'p${match.userId}';
    final matchKey = 'm${match.id}';
    if ((match.userId > 0 && _presented.contains(peerKey)) ||
        (match.id > 0 && _presented.contains(matchKey))) {
      return;
    }
    if (!context.mounted) return;

    if (match.userId > 0) _presented.add(peerKey);
    if (match.id > 0) _presented.add(matchKey);
    Future<void>.delayed(MatchCelebrationDedupe.window, () {
      _presented
        ..remove(peerKey)
        ..remove(matchKey);
    });
    MatchCelebrationDedupe.mark(match.id, match.userId);
    MatchCelebrationDedupe.isActive = true;
    MatchCelebrationDedupe.activePeerUserId = match.userId;
    MatchCelebrationDedupe.activeMatchId = match.id;

    final currentProfile = _userInfoToProfile(userInfo);
    final matchedProfile = UserProfile(
      id: match.userId,
      firstName: match.firstName,
      lastName: match.lastName ?? '',
      email: '',
    );

    // Root navigator so the overlay also covers the shell's bottom nav.
    final navigator = Navigator.of(context, rootNavigator: true);
    final router = GoRouter.of(context);
    var closed = false;
    void close() {
      if (closed) return;
      closed = true;
      if (navigator.mounted && navigator.canPop()) navigator.pop();
    }

    try {
      await MatchFoundPage.show(
        navigator,
        currentUser: currentProfile,
        matchedUser: matchedProfile,
        matchId: match.id > 0 ? match.id.toString() : match.userId.toString(),
        currentUserAvatarUrl: userInfo?.avatarUrl,
        matchedUserAvatarUrl: matchedAvatarUrl ?? match.primaryImageUrl,
        onKeepSwiping: close,
        onSendMessage: () {
          close();
          final name = Uri.encodeComponent(match.firstName);
          final avatar = match.primaryImageUrl != null
              ? '&avatarUrl=${Uri.encodeComponent(match.primaryImageUrl!)}'
              : '';
          router.push(
            '${AppRoutes.chat}?userId=${match.userId}&userName=$name$avatar',
          );
        },
      );
    } finally {
      closed = true;
      MatchCelebrationDedupe.isActive = false;
      MatchCelebrationDedupe.activePeerUserId = null;
      MatchCelebrationDedupe.activeMatchId = null;
    }
  }

  static UserProfile _userInfoToProfile(UserInfo? info) {
    if (info == null) {
      return UserProfile(
        id: 0,
        firstName: 'You',
        lastName: '',
        email: '',
      );
    }
    return UserProfile(
      id: info.id,
      firstName: info.firstName,
      lastName: info.lastName,
      email: info.email,
      city: info.city,
      country: info.country,
    );
  }
}
