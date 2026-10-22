import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/constants/animation_constants.dart';
import '../../profile/data/models/user_profile.dart';
import '../widgets/match_celebration_overlay.dart';

/// Full-screen (root navigator) blurred route hosting [MatchCelebrationOverlay].
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
    NavigatorState navigator, {
    required UserProfile currentUser,
    required UserProfile matchedUser,
    required String matchId,
    required VoidCallback onSendMessage,
    required VoidCallback onKeepSwiping,
    String? currentUserAvatarUrl,
    String? matchedUserAvatarUrl,
  }) {
    return navigator.push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        barrierDismissible: false,
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
          if (!AppAnimations.animationsEnabled(context)) return child;
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Opaque-enough blur + brand scrim so nothing behind is readable.
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: ColoredBox(
                  color: Color.lerp(
                    const Color(0xFF12061F),
                    Theme.of(context).colorScheme.primary,
                    0.25,
                  )!.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
          MatchCelebrationOverlay(
            currentUser: currentUser,
            matchedUser: matchedUser,
            matchId: matchId,
            currentUserAvatarUrl: currentUserAvatarUrl,
            matchedUserAvatarUrl: matchedUserAvatarUrl,
            onSendMessage: onSendMessage,
            onKeepSwiping: onKeepSwiping,
          ),
        ],
      ),
    );
  }
}
