import 'package:flutter/material.dart';
import '../../features/payments/data/services/plan_limits_service.dart';
import '../../features/payments/data/models/plan_limits.dart';

/// Plan Guard Result
/// 
/// Task 3.3.1 (Phase 4): Result of plan limit check
class PlanGuardResult {
  final bool isAllowed;
  final String? errorMessage;
  final String? errorCode;
  final String? featureName;
  final bool upgradeRequired;
  final int? remaining;
  final int? limit;
  final String? resetTime;

  PlanGuardResult({
    required this.isAllowed,
    this.errorMessage,
    this.errorCode,
    this.featureName,
    this.upgradeRequired = false,
    this.remaining,
    this.limit,
    this.resetTime,
  });

  factory PlanGuardResult.allowed() => PlanGuardResult(isAllowed: true);

  factory PlanGuardResult.denied({
    required String message,
    String? errorCode,
    String? featureName,
    bool upgradeRequired = true,
    int? remaining,
    int? limit,
    String? resetTime,
  }) =>
      PlanGuardResult(
        isAllowed: false,
        errorMessage: message,
        errorCode: errorCode,
        featureName: featureName,
        upgradeRequired: upgradeRequired,
        remaining: remaining,
        limit: limit,
        resetTime: resetTime,
      );
}

/// Plan Guard
/// 
/// Task 3.3.1 (Phase 4): Check plan limits before performing actions
/// 
/// Usage:
/// ```dart
/// // In a widget/provider
/// final planLimitsService = ref.read(planLimitsServiceProvider);
/// final guard = PlanGuard(planLimitsService);
/// 
/// // Before superliking
/// final result = await guard.canSuperlike();
/// if (!result.isAllowed) {
///   ScaffoldMessenger.of(context).showSnackBar(
///     SnackBar(content: Text(result.errorMessage ?? 'Action not allowed')),
///   );
///   return;
/// }
/// // Perform superlike...
/// ```
class PlanGuard {
  final PlanLimitsService _planLimitsService;

  PlanGuard(this._planLimitsService);

  /// Check if user can swipe (either direction)
  Future<PlanGuardResult> canSwipe() async {
    try {
      final limits = await _planLimitsService.getPlanLimits();
      final usage = limits.usage.swipes;

      if (usage.isUnlimited) {
        return PlanGuardResult.allowed();
      }

      if (usage.remaining <= 0) {
        return PlanGuardResult.denied(
          message: 'You\'ve reached your daily swipe limit. Upgrade for unlimited swipes!',
          errorCode: 'SWIPE_LIMIT_REACHED',
          featureName: 'unlimited_swipes',
          upgradeRequired: true,
          remaining: 0,
          limit: usage.limit,
          resetTime: limits.timestamps.resetsAt.toIso8601String(),
        );
      }

      return PlanGuardResult.allowed();
    } catch (e) {
      // Default to allowing if check fails (avoid blocking users due to network issues)
      return PlanGuardResult.allowed();
    }
  }

  /// Check if user can like another user
  Future<PlanGuardResult> canLike() async {
    try {
      final limits = await _planLimitsService.getPlanLimits();
      final usage = limits.usage.likes;

      if (usage.isUnlimited) {
        return PlanGuardResult.allowed();
      }

      if (usage.remaining <= 0) {
        return PlanGuardResult.denied(
          message: 'You\'ve reached your daily like limit. Upgrade for unlimited likes!',
          errorCode: 'LIKE_LIMIT_REACHED',
          featureName: 'unlimited_likes',
          upgradeRequired: true,
          remaining: 0,
          limit: usage.limit,
          resetTime: limits.timestamps.resetsAt.toIso8601String(),
        );
      }

      return PlanGuardResult.allowed();
    } catch (e) {
      return PlanGuardResult.allowed();
    }
  }

  /// Check if user can superlike another user
  Future<PlanGuardResult> canSuperlike() async {
    try {
      final limits = await _planLimitsService.getPlanLimits();
      final usage = limits.usage.superlikes;

      if (usage.isUnlimited) {
        return PlanGuardResult.allowed();
      }

      if (usage.remaining <= 0) {
        return PlanGuardResult.denied(
          message: 'You\'ve used all your Super Likes today. Get more with Premium!',
          errorCode: 'SUPERLIKE_LIMIT_REACHED',
          featureName: 'superlikes',
          upgradeRequired: true,
          remaining: 0,
          limit: usage.limit,
          resetTime: limits.timestamps.resetsAt.toIso8601String(),
        );
      }

      return PlanGuardResult.allowed();
    } catch (e) {
      return PlanGuardResult.allowed();
    }
  }

  /// Check if user can send more messages
  Future<PlanGuardResult> canSendMessage() async {
    try {
      final limits = await _planLimitsService.getPlanLimits();
      final usage = limits.usage.messages;

      if (usage.isUnlimited) {
        return PlanGuardResult.allowed();
      }

      if (usage.activeConversations >= usage.conversationLimit) {
        return PlanGuardResult.denied(
          message: 'You\'ve reached your conversation limit. Upgrade for unlimited messaging!',
          errorCode: 'MESSAGE_LIMIT_REACHED',
          featureName: 'unlimited_messages',
          upgradeRequired: true,
          remaining: 0,
          limit: usage.conversationLimit,
        );
      }

      return PlanGuardResult.allowed();
    } catch (e) {
      return PlanGuardResult.allowed();
    }
  }

  /// Check if user has access to advanced filters
  Future<PlanGuardResult> canUseAdvancedFilters() async {
    try {
      final limits = await _planLimitsService.getPlanLimits();

      if (limits.features.advancedFilters) {
        return PlanGuardResult.allowed();
      }

      return PlanGuardResult.denied(
        message: 'Advanced filters are a Premium feature. Upgrade to access!',
        errorCode: 'FEATURE_NOT_AVAILABLE',
        featureName: 'advanced_filters',
        upgradeRequired: true,
      );
    } catch (e) {
      return PlanGuardResult.denied(
        message: 'Unable to verify feature access. Please try again.',
        upgradeRequired: false,
      );
    }
  }

  /// Check if user can see who liked them
  Future<PlanGuardResult> canSeeWhoLikedMe() async {
    try {
      final limits = await _planLimitsService.getPlanLimits();

      if (limits.features.seeWhoLikedMe) {
        return PlanGuardResult.allowed();
      }

      return PlanGuardResult.denied(
        message: 'See who likes you is a Premium feature. Upgrade to reveal!',
        errorCode: 'FEATURE_NOT_AVAILABLE',
        featureName: 'see_who_liked_me',
        upgradeRequired: true,
      );
    } catch (e) {
      return PlanGuardResult.denied(
        message: 'Unable to verify feature access. Please try again.',
        upgradeRequired: false,
      );
    }
  }

  /// Check if user can use rewind (undo last swipe)
  Future<PlanGuardResult> canRewind() async {
    try {
      final limits = await _planLimitsService.getPlanLimits();

      if (limits.features.rewind) {
        return PlanGuardResult.allowed();
      }

      return PlanGuardResult.denied(
        message: 'Rewind is a Premium feature. Upgrade to undo swipes!',
        errorCode: 'FEATURE_NOT_AVAILABLE',
        featureName: 'rewind',
        upgradeRequired: true,
      );
    } catch (e) {
      return PlanGuardResult.denied(
        message: 'Unable to verify feature access. Please try again.',
        upgradeRequired: false,
      );
    }
  }

  /// Check if user can use passport (change location)
  Future<PlanGuardResult> canUsePassport() async {
    try {
      final limits = await _planLimitsService.getPlanLimits();

      if (limits.features.passport) {
        return PlanGuardResult.allowed();
      }

      return PlanGuardResult.denied(
        message: 'Passport is a Premium feature. Upgrade to swipe anywhere!',
        errorCode: 'FEATURE_NOT_AVAILABLE',
        featureName: 'passport',
        upgradeRequired: true,
      );
    } catch (e) {
      return PlanGuardResult.denied(
        message: 'Unable to verify feature access. Please try again.',
        upgradeRequired: false,
      );
    }
  }

  /// Check if user can use boost
  Future<PlanGuardResult> canUseBoost() async {
    try {
      final limits = await _planLimitsService.getPlanLimits();

      if (limits.features.boost) {
        return PlanGuardResult.allowed();
      }

      return PlanGuardResult.denied(
        message: 'Boost is a Premium feature. Upgrade to get more visibility!',
        errorCode: 'FEATURE_NOT_AVAILABLE',
        featureName: 'boost',
        upgradeRequired: true,
      );
    } catch (e) {
      return PlanGuardResult.denied(
        message: 'Unable to verify feature access. Please try again.',
        upgradeRequired: false,
      );
    }
  }

  /// Check if user can make video calls
  Future<PlanGuardResult> canMakeVideoCall() async {
    try {
      final limits = await _planLimitsService.getPlanLimits();

      if (limits.features.videoCalls) {
        return PlanGuardResult.allowed();
      }

      return PlanGuardResult.denied(
        message: 'Video calls are a Premium feature. Upgrade to connect face-to-face!',
        errorCode: 'FEATURE_NOT_AVAILABLE',
        featureName: 'video_calls',
        upgradeRequired: true,
      );
    } catch (e) {
      return PlanGuardResult.denied(
        message: 'Unable to verify feature access. Please try again.',
        upgradeRequired: false,
      );
    }
  }

  /// Check if user has incognito mode
  Future<PlanGuardResult> canUseIncognitoMode() async {
    try {
      final limits = await _planLimitsService.getPlanLimits();

      if (limits.features.incognitoMode) {
        return PlanGuardResult.allowed();
      }

      return PlanGuardResult.denied(
        message: 'Incognito Mode is a Premium feature. Upgrade to browse privately!',
        errorCode: 'FEATURE_NOT_AVAILABLE',
        featureName: 'incognito_mode',
        upgradeRequired: true,
      );
    } catch (e) {
      return PlanGuardResult.denied(
        message: 'Unable to verify feature access. Please try again.',
        upgradeRequired: false,
      );
    }
  }

  /// Check any feature by name
  Future<PlanGuardResult> canUseFeature(String featureName) async {
    try {
      final limits = await _planLimitsService.getPlanLimits();

      if (limits.hasFeature(featureName)) {
        return PlanGuardResult.allowed();
      }

      return PlanGuardResult.denied(
        message: 'This feature requires a Premium subscription.',
        errorCode: 'FEATURE_NOT_AVAILABLE',
        featureName: featureName,
        upgradeRequired: true,
      );
    } catch (e) {
      return PlanGuardResult.denied(
        message: 'Unable to verify feature access. Please try again.',
        upgradeRequired: false,
      );
    }
  }

  /// Get remaining count for a limit type
  Future<int?> getRemainingCount(String limitType) async {
    try {
      final limits = await _planLimitsService.getPlanLimits();

      switch (limitType) {
        case 'swipes':
          return limits.usage.swipes.isUnlimited ? -1 : limits.usage.swipes.remaining;
        case 'likes':
          return limits.usage.likes.isUnlimited ? -1 : limits.usage.likes.remaining;
        case 'superlikes':
          return limits.usage.superlikes.isUnlimited ? -1 : limits.usage.superlikes.remaining;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Record usage after successful action (optimistic local update)
  void recordUsage(String limitType) {
    _planLimitsService.incrementUsage(limitType);
  }
}

/// Extension for easy UI handling of PlanGuardResult
extension PlanGuardResultUI on PlanGuardResult {
  /// Show snackbar if action is denied
  void showSnackbarIfDenied(BuildContext context, {VoidCallback? onUpgrade}) {
    if (!isAllowed && errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage!),
          action: upgradeRequired
              ? SnackBarAction(
                  label: 'Upgrade',
                  onPressed: () {
                    onUpgrade?.call();
                  },
                )
              : null,
        ),
      );
    }
  }
}

