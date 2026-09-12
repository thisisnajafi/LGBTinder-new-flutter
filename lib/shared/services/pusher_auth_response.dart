import 'dart:convert';

/// Laravel / Pusher broadcasting auth payloads for the native Channels SDK.
class PusherAuthResponse {
  PusherAuthResponse._();

  static const _allowedKeys = {'auth', 'channel_data', 'shared_secret'};

  /// Payload the Android/iOS Pusher SDK accepts (string values only).
  static Map<String, String>? toNativeAuth(dynamic raw) {
    final normalized = normalize(raw);
    if (normalized == null) return null;

    final auth = normalized['auth']?.toString() ?? '';
    if (!auth.contains(':')) return null;

    final native = <String, String>{'auth': auth};
    final channelData = _stringify(normalized['channel_data']);
    if (channelData != null) native['channel_data'] = channelData;
    final sharedSecret = _stringify(normalized['shared_secret']);
    if (sharedSecret != null) native['shared_secret'] = sharedSecret;
    return native;
  }

  /// Returns only the keys Android/iOS Pusher clients accept.
  static Map<String, dynamic>? normalize(dynamic raw) {
    final map = _asStringKeyedMap(raw);
    if (map == null) return null;

    final reconstructed = _authFromKeyedSignature(map);
    if (reconstructed != null) {
      return reconstructed;
    }

    if (_hasAuth(map)) {
      final auth = _authString(map['auth']);
      if (auth == null) return null;
      return {
        'auth': auth,
        if (map['channel_data'] != null) 'channel_data': map['channel_data'],
        if (map['shared_secret'] != null) 'shared_secret': map['shared_secret'],
      };
    }

    for (final nestedKey in const ['data', 'body', 'result', 'payload']) {
      final nested = map[nestedKey];
      if (nested is Map) {
        final found = normalize(nested);
        if (found != null) return found;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic raw) {
    if (raw is! Map) return null;
    return {
      for (final entry in raw.entries) entry.key.toString(): entry.value,
    };
  }

  static bool _hasAuth(Map<String, dynamic> map) {
    return _authString(map['auth']) != null;
  }

  static String? _authString(dynamic value) {
    if (value is Map) {
      return _authFromKeyedSignature(_asStringKeyedMap(value) ?? const {})?['auth']
          ?.toString();
    }
    final auth = value?.toString() ?? '';
    return auth.contains(':') ? auth : null;
  }

  /// `{ "e1bc13af2989f44cc18a": "signature" }` → `{ auth: "key:signature" }`.
  static Map<String, dynamic>? _authFromKeyedSignature(Map<String, dynamic> map) {
    if (map.length != 1) return null;
    final entry = map.entries.first;
    final key = entry.key.trim();
    final value = entry.value?.toString() ?? '';
    if (key.isEmpty || value.isEmpty || key.contains(':')) return null;
    if (!_looksLikePusherKey(key) || _allowedKeys.contains(key)) return null;
    return {'auth': '$key:$value'};
  }

  static bool _looksLikePusherKey(String value) {
    return RegExp(r'^[a-f0-9]{16,32}$').hasMatch(value);
  }

  static String? _stringify(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is Map || value is List) {
      return jsonEncode(value);
    }
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  /// App key prefix from `key:signature`. Null if the payload is unusable.
  static String? appKeyFromAuth(Map<String, dynamic> authPayload) {
    final auth = authPayload['auth']?.toString() ?? '';
    final colon = auth.indexOf(':');
    if (colon <= 0) return null;
    return auth.substring(0, colon);
  }
}
