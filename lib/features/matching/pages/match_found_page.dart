import 'package:flutter/material.dart';

import '../../profile/data/models/user_profile.dart';
import '../widgets/match_celebration_overlay.dart';

/// Transparent full-screen route hosting [MatchCelebrationOverlay].
class MatchFoundPage extends StatelessWidget {
  final UserProfile currentUser;
  final UserProfile matchedUser;
  final String? currentUserAvatarUrl;
  final String? matchedUserAvatarUrl;
  final String matchId;
  final VoidCallback onSendMessage;
  final VoidCallback onKeepSwiping;

  const MatchFoundPage({
    super.key,
    required this.currentUser,
    required this.matchedUser,
    required this.matchId,
    required this.onSendMessage,
    required this.onKeepSwiping,
    this.currentUserAvatarUrl,
    this.matchedUserAvatarUrl,
  });

  /// Push as a transparent overlay on top of the current route.
  static Future<void> show(
    BuildContext context, {
    required UserProfile currentUser,
    required UserProfile matchedUser,
    required String matchId,
    required VoidCallback onSendMessage,
    required VoidCallback onKeepSwiping,
    String? currentUserAvatarUrl,
    String? matchedUserAvatarUrl,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return MatchFoundPage(
            currentUser: currentUser,
            matchedUser: matchedUser,
            matchId: matchId,
            currentUserAvatarUrl: currentUserAvatarUrl,
            matchedUserAvatarUrl: matchedUserAvatarUrl,
            onSendMessage: onSendMessage,
            onKeepSwiping: onKeepSwiping,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MatchCelebrationOverlay(
        currentUser: currentUser,
        matchedUser: matchedUser,
        matchId: matchId,
        currentUserAvatarUrl: currentUserAvatarUrl,
        matchedUserAvatarUrl: matchedUserAvatarUrl,
        onSendMessage: onSendMessage,
        onKeepSwiping: onKeepSwiping,
      ),
    );
  }
}
