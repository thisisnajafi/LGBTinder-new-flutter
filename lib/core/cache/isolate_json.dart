import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Payloads smaller than this stay on the caller isolate (spawn cost dominates).
const int kIsolateJsonMinChars = 2048;

/// Decode a JSON object, using [compute] when the string is large (PERF-INFRA-006).
Future<Map<String, dynamic>> decodeJsonMapIsolate(String raw) async {
  if (raw.length < kIsolateJsonMinChars) {
    return decodeJsonMapSync(raw);
  }
  return compute(decodeJsonMapSync, raw);
}

/// Top-level entry for [compute].
Map<String, dynamic> decodeJsonMapSync(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return Map<String, dynamic>.from(decoded);
  throw FormatException('Expected a JSON object, got ${decoded.runtimeType}');
}
