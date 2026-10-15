import 'call_log_labels.dart';

/// Local "already in a call" is only a hint. POST /busy after the server
/// still has a different live call.
class CallBusyConfirmation {
  CallBusyConfirmation._();

  static bool serverConfirmsBusy({
    required String incomingCallId,
    int? serverCallId,
    String? serverStatus,
  }) {
    if (incomingCallId.isEmpty) return false;
    if (serverCallId == null || serverCallId <= 0) return false;
    if (serverCallId.toString() == incomingCallId) return false;
    return CallLogLabels.isLiveStatus((serverStatus ?? '').toLowerCase());
  }
}
