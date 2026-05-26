import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_router.dart';
import '../../profile/data/models/user_profile.dart';
import '../../user/data/models/user_info.dart';
import '../../user/providers/user_providers.dart';
import '../data/models/match.dart' as match_models;
import '../pages/match_found_page.dart';

/// Shows the premium match celebration overlay for a mutual match.
class MatchCelebrationLauncher {
  MatchCelebrationLauncher._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required match_models.Match match,
    String? matchedAvatarUrl,
  }) async {
    final userInfo = ref.read(cachedCurrentUserProvider).valueOrNull;
    final currentProfile = _userInfoToProfile(userInfo);
    final matchedProfile = UserProfile(
      id: match.userId,
      firstName: match.firstName,
      lastName: match.lastName ?? '',
      email: '',
    );

    if (!context.mounted) return;

    await MatchFoundPage.show(
      context,
      currentUser: currentProfile,
      matchedUser: matchedProfile,
      matchId: match.id > 0 ? match.id.toString() : match.userId.toString(),
      currentUserAvatarUrl: userInfo?.avatarUrl,
      matchedUserAvatarUrl: matchedAvatarUrl ?? match.primaryImageUrl,
      onKeepSwiping: () => Navigator.of(context).pop(),
      onSendMessage: () {
        Navigator.of(context).pop();
        final name = Uri.encodeComponent(match.firstName);
        final avatar = match.primaryImageUrl != null
            ? '&avatarUrl=${Uri.encodeComponent(match.primaryImageUrl!)}'
            : '';
        context.push(
          '${AppRoutes.chat}?userId=${match.userId}&userName=$name$avatar',
        );
      },
    );
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
