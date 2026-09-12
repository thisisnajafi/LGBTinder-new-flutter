import '../models/incoming_call_data.dart';

class CallKitRestorePick {
  final IncomingCallData? accepted;
  final List<String> staleIds;

  const CallKitRestorePick({
    this.accepted,
    this.staleIds = const [],
  });
}

/// Pure helpers for killed-app CallKit restore (CALL-NATIVE-002).
class CallKitRestore {
  CallKitRestore._();

  /// Newest accepted native call from [FlutterCallkitIncoming.activeCalls].
  /// Older / unanswered rows are [CallKitRestorePick.staleIds].
  static CallKitRestorePick pick(Iterable<dynamic> calls) {
    IncomingCallData? newest;
    final staleIds = <String>[];
    for (final item in calls) {
      if (item is! Map) continue;
      final map = Map<dynamic, dynamic>.from(item);
      final data = IncomingCallData.fromCallKitMap(map);
      if (data == null) continue;
      final accepted =
          map['isAccepted'] == true || map['accepted'] == true;
      if (!accepted) {
        staleIds.add(data.callId);
        continue;
      }
      final newestId = int.tryParse(newest?.callId ?? '') ?? -1;
      final thisId = int.tryParse(data.callId) ?? -1;
      if (newest == null || thisId >= newestId) {
        if (newest != null) staleIds.add(newest.callId);
        newest = data;
      } else {
        staleIds.add(data.callId);
      }
    }
    return CallKitRestorePick(accepted: newest, staleIds: staleIds);
  }

  static IncomingCallData? newestAccepted(Iterable<dynamic> calls) =>
      pick(calls).accepted;
}
