/// Local busy gate for a second incoming while this device is already in a call
/// (CALL-FEAT-002). Same-call replays are not busy.
class CallLocalBusy {
  CallLocalBusy._();

  static bool shouldMarkBusy({
    required String incomingCallId,
    String? showingBannerCallId,
    String? acceptedCallId,
    int? providerActiveCallId,
    String? providerActiveCallUuid,
    int? sessionCallId,
    bool agoraInCall = false,
  }) {
    if (incomingCallId.isEmpty) return false;
    if (_sameCall(
      incomingCallId,
      showingBannerCallId: showingBannerCallId,
      acceptedCallId: acceptedCallId,
      providerActiveCallId: providerActiveCallId,
      providerActiveCallUuid: providerActiveCallUuid,
      sessionCallId: sessionCallId,
    )) {
      return false;
    }

    if (_hasId(showingBannerCallId)) return true;
    if (_hasId(acceptedCallId)) return true;
    if (providerActiveCallId != null && providerActiveCallId > 0) return true;
    if (_hasId(providerActiveCallUuid)) return true;
    if (sessionCallId != null && sessionCallId > 0) return true;
    return agoraInCall;
  }

  static bool _sameCall(
    String incomingCallId, {
    String? showingBannerCallId,
    String? acceptedCallId,
    int? providerActiveCallId,
    String? providerActiveCallUuid,
    int? sessionCallId,
  }) {
    if (_idsEqual(incomingCallId, showingBannerCallId)) return true;
    if (_idsEqual(incomingCallId, acceptedCallId)) return true;
    if (_idsEqual(incomingCallId, providerActiveCallUuid)) return true;
    if (providerActiveCallId != null &&
        providerActiveCallId > 0 &&
        providerActiveCallId.toString() == incomingCallId) {
      return true;
    }
    if (sessionCallId != null &&
        sessionCallId > 0 &&
        sessionCallId.toString() == incomingCallId) {
      return true;
    }
    return false;
  }

  static bool _hasId(String? id) => id != null && id.isNotEmpty;

  static bool _idsEqual(String incoming, String? other) =>
      _hasId(other) && other == incoming;
}
