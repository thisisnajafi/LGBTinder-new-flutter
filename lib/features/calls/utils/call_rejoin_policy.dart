/// A retry may join an existing channel only while the server still says active.
class CallRejoinPolicy {
  CallRejoinPolicy._();

  static bool isActiveStatus(String? status) {
    final raw = status?.toLowerCase().trim() ?? '';
    return raw == 'active' || raw == 'connected';
  }
}
