import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../shared/services/background_auth_store.dart';
import '../../../../shared/services/incoming_call_handler.dart';
import '../../../../shared/services/token_storage_service.dart';
import '../../utils/call_permission_lifecycle.dart';
import 'callkit_terminal_request.dart';

const MethodChannel callkitKilledChannel = MethodChannel(
  'com.lgbtfinder/callkit_killed',
);

/// Tells Android the main isolate is listening, so a Decline broadcast
/// can leave the HTTP call to Dart instead of starting another engine.
Future<void> markCallKitDartListening(bool listening) async {
  try {
    await callkitKilledChannel.invokeMethod<void>('setListening', listening);
  } catch (e) {
    AppLogger.debug(
      'CallKit listening flag skipped',
      tag: 'CallKit',
    );
  }
}

/// Background isolate entry. Android starts this when Decline/timeout
/// arrives and the main isolate is not listening.
@pragma('vm:entry-point')
Future<void> callkitBackgroundHandler() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await flushStoredCallKitActions();
  } catch (e) {
    AppLogger.warning(
      'CallKit background flush failed',
      tag: 'CallKit',
      error: e,
    );
  } finally {
    try {
      await callkitKilledChannel.invokeMethod<void>('completed');
    } catch (_) {}
  }
}

Future<void> enqueueCallKitPending(CallKitPendingAction action) async {
  final prefs = await SharedPreferences.getInstance();
  final merged = mergeCallKitPending(
    decodeCallKitPending(prefs.getString(kCallkitPendingActionsKey)),
    action,
  );
  await prefs.setString(kCallkitPendingActionsKey, encodeCallKitPending(merged));
}

Future<void> dropCallKitPending(String callId) async {
  final prefs = await SharedPreferences.getInstance();
  final remaining = decodeCallKitPending(
    prefs.getString(kCallkitPendingActionsKey),
  ).where((action) => action.callId != callId).toList();
  if (remaining.isEmpty) {
    await prefs.remove(kCallkitPendingActionsKey);
    return;
  }
  await prefs.setString(
    kCallkitPendingActionsKey,
    encodeCallKitPending(remaining),
  );
}

/// Posts a stored explicit Decline when it is still a ringing call.
/// Timeouts and stale rows are removed and logged.
Future<void> flushStoredCallKitActions() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = decodeCallKitPending(
    prefs.getString(kCallkitPendingActionsKey),
  );
  final pending = stripDeclinesDuringPermissionPrompt(
    stored,
    permissionRequestInFlight:
        CallPermissionLifecycle.blocksCallTerminalActions,
  );
  if (pending.length != stored.length) {
    if (pending.isEmpty) {
      await prefs.remove(kCallkitPendingActionsKey);
    } else {
      await prefs.setString(
        kCallkitPendingActionsKey,
        encodeCallKitPending(pending),
      );
    }
  }
  if (pending.isEmpty) return;

  final token = await _readToken(prefs);
  final origin = prefs.getString(kBackgroundApiOriginKey) ??
      (token == null ? null : ApiEndpoints.apiOrigin);
  final currentIncoming =
      (await IncomingCallHandler.loadPersisted())?.data.callId;
  final statusChecked = token != null &&
      token.isNotEmpty &&
      origin != null &&
      origin.isNotEmpty;
  final statusByCallId = <String, String?>{};
  if (statusChecked) {
    for (final action in pending) {
      if (action.kind != CallKitPendingKind.decline) continue;
      try {
        statusByCallId[action.callId] = await fetchCallRingStatus(
          callId: action.callId,
          token: token,
          apiOrigin: origin,
        );
      } catch (e) {
        AppLogger.warning(
          'Call ${action.callId} ring check failed; decline stays until the next start',
          tag: 'CallKit',
          error: e,
        );
      }
    }
  }
  final replay = declinesEligibleForReplay(
    actions: pending,
    now: DateTime.now(),
    currentIncomingCallId: currentIncoming,
    statusByCallId: statusByCallId,
    statusChecked: statusChecked,
  );
  for (final action in pending) {
    final kept = replay.any(
      (item) => item.callId == action.callId && item.kind == action.kind,
    );
    if (kept) continue;
    AppLogger.info(
      'Dropping stored CallKit ${action.kind} ${action.callId} '
      'at=${action.recordedAt?.toIso8601String() ?? 'missing'} '
      'current=$currentIncoming',
      tag: 'CallKit',
    );
  }
  if (replay.isEmpty) {
    await prefs.remove(kCallkitPendingActionsKey);
    return;
  }
  final remaining = await flushCallKitPending(
    actions: replay,
    token: token,
    apiOrigin: origin,
    post: postCallKitTerminalRequest,
  );
  if (remaining.isEmpty) {
    await prefs.remove(kCallkitPendingActionsKey);
    return;
  }
  await prefs.setString(
    kCallkitPendingActionsKey,
    encodeCallKitPending(remaining),
  );
}

Future<List<CallKitPendingAction>> flushCallKitPending({
  required List<CallKitPendingAction> actions,
  required String? token,
  required String? apiOrigin,
  required Future<int> Function(CallKitTerminalRequest request) post,
}) async {
  final remaining = <CallKitPendingAction>[];
  final ordered = [...actions]..sort((a, b) {
      if (a.kind == b.kind) return a.callId.compareTo(b.callId);
      if (a.kind == CallKitPendingKind.decline) return -1;
      if (b.kind == CallKitPendingKind.decline) return 1;
      return a.callId.compareTo(b.callId);
    });
  for (final action in ordered) {
    final request = buildCallKitTerminalRequest(
      action: action,
      token: token,
      apiOrigin: apiOrigin,
    );
    if (request == null) {
      remaining.add(action);
      continue;
    }
    try {
      final status = await post(request);
      AppLogger.info(
        'CallKit ${action.kind} ${action.callId} -> $status',
        tag: 'CallKit',
      );
      if (!callKitPendingShouldDrop(status)) {
        remaining.add(action);
      }
    } catch (e) {
      AppLogger.warning(
        'CallKit ${action.kind} ${action.callId} failed',
        tag: 'CallKit',
        error: e,
      );
      remaining.add(action);
    }
  }
  return remaining;
}

/// GET /api/calls/{id}. Empty string means the call is not ringing.
Future<String> fetchCallRingStatus({
  required String callId,
  required String token,
  required String apiOrigin,
}) async {
  final origin = apiOrigin.trim().replaceAll(RegExp(r'/+$'), '');
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 8);
  try {
    final httpRequest = await client
        .getUrl(Uri.parse('$origin/api/calls/$callId'))
        .timeout(const Duration(seconds: 8));
    httpRequest.headers.set('Authorization', 'Bearer $token');
    httpRequest.headers.set('Accept', 'application/json');
    final response =
        await httpRequest.close().timeout(const Duration(seconds: 12));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode == 404) return '';
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('status ${response.statusCode}', uri: httpRequest.uri);
    }
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      final data = decoded['data'];
      if (data is Map && data['status'] != null) {
        return data['status'].toString();
      }
    }
    return '';
  } finally {
    client.close(force: true);
  }
}

Future<int> postCallKitTerminalRequest(CallKitTerminalRequest request) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 8);
  try {
    final httpRequest = await client
        .postUrl(request.uri)
        .timeout(const Duration(seconds: 8));
    request.headers.forEach(httpRequest.headers.set);
    httpRequest.add(utf8.encode(request.body));
    final response =
        await httpRequest.close().timeout(const Duration(seconds: 12));
    await response.drain<void>().timeout(const Duration(seconds: 4));
    return response.statusCode;
  } finally {
    client.close(force: true);
  }
}

Future<String?> _readToken(SharedPreferences prefs) async {
  final mirrored = prefs.getString(kBackgroundAuthTokenKey);
  if (mirrored != null && mirrored.isNotEmpty) return mirrored;
  try {
    return await TokenStorageService().getAuthToken();
  } catch (_) {
    return null;
  }
}
