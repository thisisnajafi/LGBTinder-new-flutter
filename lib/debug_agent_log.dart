// #region agent log
// Debug-mode instrumentation: NDJSON to file, HTTP ingest, and console.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const _kEndpoint =
    'http://127.0.0.1:7242/ingest/b753b912-0470-435b-ab67-0c31848fb8d7';
const _kLogPath = r'e:\1 - laravel\1 - LGBTinder\.cursor\debug.log';

void agentLog(String location, String message, Map<String, dynamic> data,
    String hypothesisId,
    {String runId = 'run1'}) {
  final payload = {
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'hypothesisId': hypothesisId,
    'sessionId': 'debug-session',
    'runId': runId,
  };
  final line = jsonEncode(payload);
  if (kDebugMode) debugPrint('AGENT_LOG: $line');
  try {
    File(_kLogPath).writeAsStringSync('$line\n', mode: FileMode.append);
  } catch (_) {}
  http
      .post(
        Uri.parse(_kEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: line,
      )
      .catchError((_, __) => http.Response('', 500));
}
// #endregion
