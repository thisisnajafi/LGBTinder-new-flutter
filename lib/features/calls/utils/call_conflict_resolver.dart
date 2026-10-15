import '../data/models/call.dart';
import 'call_log_labels.dart';
import 'call_rejoin_policy.dart';

/// What the outgoing-call screen should do after
/// "There is already an active call with this user".
enum CallConflictAction {
  /// Fresh ACTIVE call with this peer — join it.
  rejoin,

  /// Ringing/initiating, or an ACTIVE row the client already treats as dead.
  /// End it, then start a new call.
  clearAndRetry,

  /// The live call is with someone else.
  busyElsewhere,

  /// Nothing live to clear or rejoin.
  giveUp,
}

/// Keeps the rejoin path aligned with `/calls/active`.
///
/// A ringing conflict is cleared instead of failing the screen. Stale ACTIVE
/// rows (no heartbeat, older than the 4-hour ceiling) are cleared the same way.
class CallConflictResolver {
  CallConflictResolver._();

  static const _ringing = {'initiating', 'initiated', 'ringing'};

  static CallConflictAction decide({
    required Call? existing,
    required int peerId,
    DateTime? now,
  }) {
    if (existing == null || existing.id <= 0) {
      return CallConflictAction.giveUp;
    }

    final involvesPeer =
        existing.callerId == peerId || existing.receiverId == peerId;
    if (!involvesPeer) return CallConflictAction.busyElsewhere;

    final raw = existing.status.toLowerCase();
    if (CallLogLabels.isTerminalStatus(raw)) {
      return CallConflictAction.giveUp;
    }

    final resolved = CallLogLabels.resolvedStatus(existing, now: now);
    if (_ringing.contains(raw) || CallLogLabels.isTerminalStatus(resolved)) {
      return CallConflictAction.clearAndRetry;
    }

    if (!CallRejoinPolicy.isActiveStatus(raw)) {
      return CallConflictAction.giveUp;
    }

    return CallConflictAction.rejoin;
  }
}
