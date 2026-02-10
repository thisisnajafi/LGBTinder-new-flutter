import 'discovery_profile.dart';

/// Interaction state for a discover profile (single source of truth for UI).
enum DiscoverInteractionState {
  none,
  liked,
  disliked,
  superLiked,
}

/// Sync status for a swipe that was applied locally but may not yet be confirmed by the server.
enum DiscoverSyncStatus {
  synced,
  pending,
  failed,
}

/// One discover feed entry: profile + interaction state. Cache-only; UI never shows uncached data.
class CachedDiscoverItem {
  final DiscoveryProfile profile;
  final DiscoverInteractionState interactionState;
  final DiscoverSyncStatus syncStatus;

  const CachedDiscoverItem({
    required this.profile,
    this.interactionState = DiscoverInteractionState.none,
    this.syncStatus = DiscoverSyncStatus.synced,
  });

  int get id => profile.id;

  CachedDiscoverItem copyWith({
    DiscoveryProfile? profile,
    DiscoverInteractionState? interactionState,
    DiscoverSyncStatus? syncStatus,
  }) {
    return CachedDiscoverItem(
      profile: profile ?? this.profile,
      interactionState: interactionState ?? this.interactionState,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'interaction_state': interactionState.name,
      'sync_status': syncStatus.name,
    };
  }

  static CachedDiscoverItem fromJson(Map<String, dynamic> json) {
    final profileMap = json['profile'] as Map<String, dynamic>?;
    if (profileMap == null) throw ArgumentError('CachedDiscoverItem missing profile');
    final profile = DiscoveryProfile.fromJson(profileMap);
    final stateStr = json['interaction_state'] as String? ?? 'none';
    final interactionState = DiscoverInteractionState.values.firstWhere(
      (e) => e.name == stateStr,
      orElse: () => DiscoverInteractionState.none,
    );
    final syncStr = json['sync_status'] as String? ?? 'synced';
    final syncStatus = DiscoverSyncStatus.values.firstWhere(
      (e) => e.name == syncStr,
      orElse: () => DiscoverSyncStatus.synced,
    );
    return CachedDiscoverItem(
      profile: profile,
      interactionState: interactionState,
      syncStatus: syncStatus,
    );
  }
}
