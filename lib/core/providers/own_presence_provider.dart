import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live online/offline flag for the authenticated user (own profile indicator).
///
/// Updated by [PresenceService] after successful markOnline / markOffline,
/// and optionally by API profile payloads. Not driven solely by cached profile
/// `is_online`, which can be stale relative to app lifecycle.
final ownPresenceProvider =
    NotifierProvider<OwnPresenceNotifier, bool>(OwnPresenceNotifier.new);

class OwnPresenceNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setOnline(bool isOnline) {
    state = isOnline;
  }

  void markOnline() => state = true;

  void markOffline() => state = false;
}
