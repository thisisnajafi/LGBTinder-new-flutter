import '../../../shared/models/user_tier.dart';
import '../data/models/user_profile.dart';

String? _nonEmptyPlanString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text == 'null') return null;
  return text;
}

String? _nestedPlanTitle(dynamic value) {
  if (value is! Map) return null;
  return _nonEmptyPlanString(value['title']) ??
      _nonEmptyPlanString(value['name']) ??
      _nonEmptyPlanString(value['plan_name']);
}

/// Plan title from the other-user profile payload (`plan_type`, nested plan, etc.).
String? profilePlanNameFromPayload(UserProfile profile) {
  final data = profile.additionalData;
  if (data == null) return null;

  final direct = _nonEmptyPlanString(data['plan_type']) ??
      _nonEmptyPlanString(data['plan_name']) ??
      _nonEmptyPlanString(data['plan_title']) ??
      _nonEmptyPlanString(data['subscription_plan']);
  if (direct != null) return direct;

  return _nestedPlanTitle(data['plan']) ??
      _nestedPlanTitle(data['active_plan']) ??
      _nestedPlanTitle(data['current_plan']) ??
      _nestedPlanTitle(
        data['active_plan'] is Map ? data['active_plan']['plan'] : null,
      );
}

int? profilePlanIdFromPayload(UserProfile profile) {
  final data = profile.additionalData;
  if (data == null) return null;
  final raw = data['plan_id'] ??
      (data['plan'] is Map ? data['plan']['id'] : null) ??
      (data['active_plan'] is Map ? data['active_plan']['plan_id'] : null);
  if (raw is int) return raw;
  return int.tryParse(raw?.toString() ?? '');
}

/// Resolve another user's plan tier from profile payload (not the viewer's tier).
UserTier tierFromUserProfile(UserProfile profile) {
  final planName = profilePlanNameFromPayload(profile);
  final planId = profilePlanIdFromPayload(profile);

  if (planName != null || planId != null) {
    return userTierFromPlan(planId: planId, planName: planName);
  }
  if (profile.isPremium == true) return UserTier.silder;
  return UserTier.basid;
}

/// User-facing plan badge text (Basic / Silver / Golden).
String planBadgeLabelFromUserProfile(UserProfile profile) {
  final raw = profilePlanNameFromPayload(profile);
  if (raw != null) {
    final lower = raw.toLowerCase();
    if (lower == 'basid') return 'Basic';
    if (lower == 'silder' || lower == 'silver') return 'Silver';
    return raw;
  }
  return tierFromUserProfile(profile).displayLabel;
}
