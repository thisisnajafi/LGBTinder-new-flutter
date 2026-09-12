import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Bridge for non-Riverpod services (FCM) to know which chat is open.
class ActiveChatPeerBridge {
  static const prefsKey = 'active_chat_peer_user_id';
  static const conversationPrefsKey = 'active_chat_conversation_id';

  /// Sync callback used while the app isolate has Riverpod wired up.
  static int? Function()? getActivePeerUserId;

  /// Sync callback for the subscribed conversation id.
  static int? Function()? getActiveConversationId;

  /// Set during ChatPage.initState before Riverpod can be updated.
  static int? _pendingPeerUserId;

  static bool isActivePeer(int senderId) {
    if (senderId <= 0) return false;
    if (_pendingPeerUserId == senderId) return true;
    return getActivePeerUserId?.call() == senderId;
  }

  static bool isActiveConversation(int conversationId) {
    if (conversationId <= 0) return false;
    return getActiveConversationId?.call() == conversationId;
  }

  /// Persist so background isolates can also suppress (best-effort).
  static Future<void> setActivePeer(int? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null || userId <= 0) {
      await prefs.remove(prefsKey);
    } else {
      await prefs.setInt(prefsKey, userId);
    }
  }

  static Future<void> setActiveConversation(int? conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    if (conversationId == null || conversationId <= 0) {
      await prefs.remove(conversationPrefsKey);
    } else {
      await prefs.setInt(conversationPrefsKey, conversationId);
    }
  }

  static Future<void> setActiveSession({
    int? peerUserId,
    int? conversationId,
  }) async {
    await Future.wait([
      setActivePeer(peerUserId),
      setActiveConversation(conversationId),
    ]);
  }

  static Future<void> clearActiveSession() async {
    _pendingPeerUserId = null;
    await setActiveSession();
  }

  /// Marks a peer active before Riverpod state can be written (initState).
  static void primeActivePeer(int userId) {
    if (userId <= 0) return;
    _pendingPeerUserId = userId;
    unawaited(setActivePeer(userId));
  }

  static void clearPendingPeer() {
    _pendingPeerUserId = null;
  }

  static Future<int?> readActivePeerFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(prefsKey);
    if (id == null || id <= 0) return null;
    return id;
  }

  static Future<int?> readActiveConversationFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(conversationPrefsKey);
    if (id == null || id <= 0) return null;
    return id;
  }
}
