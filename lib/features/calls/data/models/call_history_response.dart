import 'call.dart';

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
    return CallHistoryResponse(
      calls: (json['calls'] as List<dynamic>?)
          ?.map((call) => Call.fromJson(call as Map<String, dynamic>))
          .toList() ?? [],
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
