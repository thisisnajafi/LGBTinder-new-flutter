/// Generic cache wrapper with TTL metadata.
class CacheEntry<T> {
  final T data;
  final DateTime cachedAt;
  final Duration ttl;

  const CacheEntry({
    required this.data,
    required this.cachedAt,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().isAfter(cachedAt.add(ttl));

  DateTime get expiresAt => cachedAt.add(ttl);

  Map<String, dynamic> toJson({
    required Map<String, dynamic> Function(T data) dataToJson,
  }) {
    return {
      'data': dataToJson(data),
      'cached_at': cachedAt.toIso8601String(),
      'ttl_ms': ttl.inMilliseconds,
    };
  }

  factory CacheEntry.fromJson({
    required Map<String, dynamic> json,
    required T Function(Map<String, dynamic> json) dataFromJson,
  }) {
    return CacheEntry<T>(
      data: dataFromJson(Map<String, dynamic>.from(json['data'] as Map)),
      cachedAt: DateTime.parse(json['cached_at'] as String),
      ttl: Duration(milliseconds: json['ttl_ms'] as int),
    );
  }

  CacheEntry<T> copyWith({
    T? data,
    DateTime? cachedAt,
    Duration? ttl,
  }) {
    return CacheEntry<T>(
      data: data ?? this.data,
      cachedAt: cachedAt ?? this.cachedAt,
      ttl: ttl ?? this.ttl,
    );
  }
}
