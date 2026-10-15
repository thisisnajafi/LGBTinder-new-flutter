import 'dart:convert';

/// Wire values stored in SharedPreferences and read by Android/iOS.
class CallKitPendingKind {
  static const String decline = 'decline';
  static const String timeout = 'timeout';

  static const Set<String> all = {decline, timeout};
}

/// One CallKit action that still needs to reach the API.
class CallKitPendingAction {
  final String callId;
  final String kind;

  const CallKitPendingAction({
    required this.callId,
    required this.kind,
  });

  Map<String, String> toJson() => {
        'callId': callId,
        'kind': kind,
      };

  static CallKitPendingAction? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final callId = raw['callId']?.toString() ?? '';
    final kind = raw['kind']?.toString() ?? '';
    if (!RegExp(r'^[0-9]+$').hasMatch(callId)) return null;
    if (!CallKitPendingKind.all.contains(kind)) return null;
    return CallKitPendingAction(callId: callId, kind: kind);
  }
}

/// A permission dialog can make CallKit emit decline. Drop those rows
/// while the prompt is up so a later flush cannot POST reject.
/// Timeouts stay so an unanswered call can still be stored as missed.
List<CallKitPendingAction> stripDeclinesDuringPermissionPrompt(
  List<CallKitPendingAction> actions, {
  required bool permissionRequestInFlight,
}) {
  if (!permissionRequestInFlight) return actions;
  return actions
      .where((action) => action.kind != CallKitPendingKind.decline)
      .toList();
}

/// Decline wins over a later timeout for the same call.
List<CallKitPendingAction> mergeCallKitPending(
  List<CallKitPendingAction> existing,
  CallKitPendingAction incoming,
) {
  final next = <CallKitPendingAction>[];
  var replaced = false;
  for (final action in existing) {
    if (action.callId != incoming.callId) {
      next.add(action);
      continue;
    }
    if (action.kind == CallKitPendingKind.decline &&
        incoming.kind == CallKitPendingKind.timeout) {
      next.add(action);
      replaced = true;
      continue;
    }
    next.add(incoming);
    replaced = true;
  }
  if (!replaced) next.add(incoming);
  return next;
}

List<CallKitPendingAction> decodeCallKitPending(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .map(CallKitPendingAction.tryParse)
        .whereType<CallKitPendingAction>()
        .toList();
  } catch (_) {
    return const [];
  }
}

String encodeCallKitPending(List<CallKitPendingAction> actions) {
  return jsonEncode(actions.map((action) => action.toJson()).toList());
}

/// HTTP call the background isolate sends for a stored CallKit action.
class CallKitTerminalRequest {
  final Uri uri;
  final Map<String, String> headers;
  final String body;

  const CallKitTerminalRequest({
    required this.uri,
    required this.headers,
    required this.body,
  });
}

/// Decline → `POST /api/calls/{id}/reject`.
/// CallKit timeout → `POST /api/calls/{id}/end` (receiver end is missed).
CallKitTerminalRequest? buildCallKitTerminalRequest({
  required CallKitPendingAction action,
  required String? token,
  required String? apiOrigin,
}) {
  final bearer = token?.trim() ?? '';
  final origin = _normalizeOrigin(apiOrigin);
  if (bearer.isEmpty || origin == null) return null;
  final path = switch (action.kind) {
    CallKitPendingKind.decline => '/api/calls/${action.callId}/reject',
    CallKitPendingKind.timeout => '/api/calls/${action.callId}/end',
    _ => null,
  };
  if (path == null) return null;
  final reason = action.kind == CallKitPendingKind.timeout
      ? 'CallKit timeout'
      : 'User rejected the call';
  return CallKitTerminalRequest(
    uri: Uri.parse('$origin$path'),
    headers: {
      'Authorization': 'Bearer $bearer',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'reason': reason}),
  );
}

/// 2xx delivered. 4xx except 401/408/429 is a terminal call the server
/// already closed, so the pending row must not retry forever.
bool callKitPendingShouldDrop(int statusCode) {
  if (statusCode >= 200 && statusCode < 300) return true;
  if (statusCode == 400 ||
      statusCode == 403 ||
      statusCode == 404 ||
      statusCode == 409 ||
      statusCode == 422) {
    return true;
  }
  return false;
}

String? _normalizeOrigin(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://${uri.host}$port';
}
