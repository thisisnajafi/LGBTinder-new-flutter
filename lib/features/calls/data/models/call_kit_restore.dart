import '../models/incoming_call_data.dart';

class CallKitRestorePick {
  final IncomingCallData? accepted;

  /// Newest unanswered CallKit row when nothing has been accepted.
  final IncomingCallData? ringing;
  final List<String> staleIds;

  const CallKitRestorePick({
    this.accepted,
    this.ringing,
    this.staleIds = const [],
  });
}

/// Pure helpers for killed-app CallKit restore (CALL-NATIVE-002).
class CallKitRestore {
  CallKitRestore._();

  /// Newest accepted native call from [FlutterCallkitIncoming.activeCalls].
  ///
  /// When an accepted call exists, every other row is stale. When nothing
  /// is accepted, the newest unanswered row stays [CallKitRestorePick.ringing]
  /// so launch does not hang up a live incoming call.
  static CallKitRestorePick pick(Iterable<dynamic> calls) {
    IncomingCallData? newestAccepted;
    final unanswered = <IncomingCallData>[];
    final staleIds = <String>[];
    for (final item in calls) {
      if (item is! Map) continue;
      final map = Map<dynamic, dynamic>.from(item);
      final data = IncomingCallData.fromCallKitMap(map);
      if (data == null) continue;
      final accepted =
          map['isAccepted'] == true || map['accepted'] == true;
      if (!accepted) {
        unanswered.add(data);
        continue;
      }
      final newestId = int.tryParse(newestAccepted?.callId ?? '') ?? -1;
      final thisId = int.tryParse(data.callId) ?? -1;
      if (newestAccepted == null || thisId >= newestId) {
        if (newestAccepted != null) staleIds.add(newestAccepted.callId);
        newestAccepted = data;
      } else {
        staleIds.add(data.callId);
      }
    }
    if (newestAccepted != null) {
      for (final row in unanswered) {
        staleIds.add(row.callId);
      }
      return CallKitRestorePick(accepted: newestAccepted, staleIds: staleIds);
    }

    IncomingCallData? newestRinging;
    for (final row in unanswered) {
      final newestId = int.tryParse(newestRinging?.callId ?? '') ?? -1;
      final thisId = int.tryParse(row.callId) ?? -1;
      if (newestRinging == null || thisId >= newestId) {
        if (newestRinging != null) staleIds.add(newestRinging.callId);
        newestRinging = row;
      } else {
        staleIds.add(row.callId);
      }
    }
    return CallKitRestorePick(ringing: newestRinging, staleIds: staleIds);
  }

  static IncomingCallData? newestAccepted(Iterable<dynamic> calls) =>
      pick(calls).accepted;
}
