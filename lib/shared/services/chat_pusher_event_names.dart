/// Canonical Pusher event names from `lgbtinder-backend/config/chat_broadcasting.php`.
///
/// Keep [fromBackendConfig] in lockstep with that file's `events` map values
/// and [legacyFromBackendConfig] with `legacy_events`.
class ChatPusherEventNames {
  ChatPusherEventNames._();

  static const messageSent = 'MessageSent';
  static const messageRead = 'MessageRead';
  static const messageDeleted = 'MessageDeleted';
  static const messageEdited = 'MessageEdited';
  static const messageReacted = 'MessageReacted';
  static const messageDelivered = 'MessageDelivered';
  static const userTyping = 'UserTyping';
  static const userStoppedTyping = 'UserStoppedTyping';
  static const messageExpired = 'MessageExpired';
  static const screenshotDetected = 'ScreenshotDetected';
  static const userStatus = 'user.status';
  static const callIncoming = 'call.incoming';
  static const callAccepted = 'call.accepted';
  static const callRejected = 'call.rejected';
  static const callEnded = 'call.ended';
  static const callBusy = 'call.busy';
  static const callInitiated = 'call.initiated';
  static const newMatch = 'new.match';
  static const newLike = 'new.like';
  static const planUpdated = 'plan.updated';

  /// Values of config `chat_broadcasting.events` — Flutter must handle every entry.
  static const Set<String> fromBackendConfig = {
    messageSent,
    messageRead,
    messageDeleted,
    messageEdited,
    messageReacted,
    messageDelivered,
    userTyping,
    userStoppedTyping,
    messageExpired,
    screenshotDetected,
    userStatus,
    callIncoming,
    callAccepted,
    callRejected,
    callEnded,
    callBusy,
    callInitiated,
    newMatch,
  };

  /// Values of config `chat_broadcasting.legacy_events`.
  static const Set<String> legacyFromBackendConfig = {
    'message.sent',
    'message.read',
    'message.deleted',
    'message.edited',
    'message.reacted',
    'message.delivered',
    'user.typing',
    'user.stopped_typing',
    'message.expired',
    'screenshot.detected',
    'presence.updated',
  };

  /// Extra client aliases that are not in config (older app builds / docs).
  static const Set<String> extraClientAliases = {
    'NewLike',
    'like.created',
    'new_like',
    'NewMatch',
    'match.created',
    'new_match',
    'PlanUpdated',
    'plan_updated',
    'subscription.updated',
  };

  static const Map<String, String> _toCanonical = {
    'message.sent': messageSent,
    'message.read': messageRead,
    'message.deleted': messageDeleted,
    'message.edited': messageEdited,
    'message.reacted': messageReacted,
    'message.delivered': messageDelivered,
    'user.typing': userTyping,
    'user.stopped_typing': userStoppedTyping,
    'message.expired': messageExpired,
    'screenshot.detected': screenshotDetected,
    'presence.updated': userStatus,
    callInitiated: callIncoming,
    'NewLike': newLike,
    'like.created': newLike,
    'new_like': newLike,
    'NewMatch': newMatch,
    'match.created': newMatch,
    'new_match': newMatch,
    'PlanUpdated': planUpdated,
    'plan_updated': planUpdated,
    'subscription.updated': planUpdated,
  };

  static String canonicalize(String eventName) {
    return _toCanonical[eventName] ?? eventName;
  }

  static bool isHandled(String eventName) {
    if (fromBackendConfig.contains(eventName)) return true;
    if (legacyFromBackendConfig.contains(eventName)) return true;
    if (extraClientAliases.contains(eventName)) return true;
    return _toCanonical.containsKey(eventName);
  }
}
