import 'call.dart';

/// Safe type parsing helpers for call history response
/// FIXED: Task 5.2.1 - Added safe type parsing to prevent crashes
int _safeParseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

bool _safeParseBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return defaultValue;
}

/// Call history response model
class CallHistoryResponse {
  final List<Call> calls;
  final int total;
  final int page;
  final int perPage;
  final bool hasMore;

  CallHistoryResponse({
    required this.calls,
    required this.total,
    required this.page,
    required this.perPage,
    required this.hasMore,
  });

  factory CallHistoryResponse.fromJson(Map<String, dynamic> json) {
    // FIXED: Safe list parsing with error handling for individual items
    List<Call> parsedCalls = [];
    if (json['calls'] != null && json['calls'] is List) {
      for (var call in json['calls'] as List) {
        if (call != null && call is Map) {
          try {
            parsedCalls.add(Call.fromJson(Map<String, dynamic>.from(call)));
          } catch (e) {
            // Skip invalid call entries instead of crashing
          }
        }
      }
    }
    
    return CallHistoryResponse(
      calls: parsedCalls,
      total: _safeParseInt(json['total']),
      page: _safeParseInt(json['page'], defaultValue: 1),
      perPage: _safeParseInt(json['per_page'], defaultValue: 20),
      hasMore: _safeParseBool(json['has_more']),
    );
  }
}
