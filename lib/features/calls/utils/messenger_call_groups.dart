import '../../../core/utils/media_url.dart';
import '../data/models/call.dart';
import 'call_log_labels.dart';
import '../../../core/utils/media_url.dart';

enum MessengerCallFilter { all, missed, incoming, outgoing }

/// One row in the messenger Calls list (consecutive calls with the same person).
class MessengerCallGroup {
  final int peerId;
  final String peerName;
  final String? peerAvatarUrl;
  final Call latest;
  final int count;
  final int missedCount;

  const MessengerCallGroup({
    required this.peerId,
    required this.peerName,
    required this.peerAvatarUrl,
    required this.latest,
    required this.count,
    required this.missedCount,
  });

  bool isOutgoing(int currentUserId) => latest.callerId == currentUserId;
}

bool messengerCallMatchesFilter({
  required Call call,
  required MessengerCallFilter filter,
  required int currentUserId,
}) {
  switch (filter) {
    case MessengerCallFilter.all:
      return true;
    case MessengerCallFilter.missed:
      return CallLogLabels.isMissedOrDeclined(
        call: call,
        currentUserId: currentUserId,
      );
    case MessengerCallFilter.incoming:
      return call.receiverId == currentUserId;
    case MessengerCallFilter.outgoing:
      return call.callerId == currentUserId;
  }
}

String messengerPeerName(Call call, int currentUserId) {
  final peer =
      call.callerId == currentUserId ? call.receiver : call.caller;
  if (peer == null) return 'User';
  final name = '${peer.firstName} ${peer.lastName}'.trim();
  return name.isEmpty ? 'User' : name;
}

String? messengerPeerAvatar(Call call, int currentUserId) {
  final peer =
      call.callerId == currentUserId ? call.receiver : call.caller;
  return MediaUrl.resolve(peer?.avatarUrl);
}

String? messengerPeerAvatarFromCalls(List<Call> calls, int currentUserId) {
  for (final call in calls) {
    final url = messengerPeerAvatar(call, currentUserId);
    if (url != null && url.isNotEmpty) return url;
  }
  return null;
}

/// Newest-first calls grouped into consecutive streaks with the same person.
List<MessengerCallGroup> groupMessengerCalls({
  required List<Call> calls,
  required int currentUserId,
  MessengerCallFilter filter = MessengerCallFilter.all,
}) {
  final filtered = calls
      .where(
        (call) => messengerCallMatchesFilter(
          call: call,
          filter: filter,
          currentUserId: currentUserId,
        ),
      )
      .toList()
    ..sort((a, b) => b.timelineTimestamp.compareTo(a.timelineTimestamp));

  final streaks = <List<Call>>[];
  for (final call in filtered) {
    final peerId = call.getOtherParticipantId(currentUserId);
    if (peerId <= 0) continue;
    if (streaks.isNotEmpty &&
        streaks.last.first.getOtherParticipantId(currentUserId) == peerId) {
      streaks.last.add(call);
    } else {
      streaks.add([call]);
    }
  }

  return [
    for (final streak in streaks)
      MessengerCallGroup(
        peerId: streak.first.getOtherParticipantId(currentUserId),
        peerName: messengerPeerName(streak.first, currentUserId),
        peerAvatarUrl: messengerPeerAvatarFromCalls(streak, currentUserId),
        latest: streak.first,
        count: streak.length,
        missedCount: streak
            .where(
              (call) => CallLogLabels.isMissedOrDeclined(
                call: call,
                currentUserId: currentUserId,
              ),
            )
            .length,
      ),
  ];
}
