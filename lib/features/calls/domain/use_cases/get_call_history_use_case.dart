import '../../data/repositories/call_repository.dart';
import '../../data/models/call.dart';

/// Use Case: GetCallHistoryUseCase
/// Handles retrieving user's call history
class GetCallHistoryUseCase {
  final CallRepository _callRepository;

  GetCallHistoryUseCase(this._callRepository);

  /// Execute get call history use case
  /// Returns [List<Call>] with user's call history
  Future<List<Call>> execute({
    int? page,
    int? limit,
    String? status,
    String? callType,
  }) async {
    try {
      // Set default values if not provided
      final effectivePage = page ?? 1;
      final effectiveLimit = limit ?? 20;

      // Validate parameters
      if (effectivePage < 1) {
        throw Exception('Page must be greater than 0');
      }

      if (effectiveLimit < 1 || effectiveLimit > 100) {
        throw Exception('Limit must be between 1 and 100');
      }

      if (status != null && !['initiated', 'ringing', 'connected', 'ended', 'missed', 'declined'].contains(status)) {
        throw Exception('Invalid status filter');
      }

      if (callType != null && !['audio', 'video'].contains(callType)) {
        throw Exception('Invalid call type filter');
      }

      final calls = await _callRepository.getCallHistory(
        page: effectivePage,
        limit: effectiveLimit,
        status: status,
        callType: callType,
      );

      // Sort calls by most recent first
      calls.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      return calls;
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }

  /// Get recent calls (last 7 days)
  Future<List<Call>> getRecentCalls({int limit = 10}) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final allCalls = await execute(limit: limit);

      // Filter for recent calls (this would ideally be done server-side)
      return allCalls.where((call) => call.startedAt.isAfter(sevenDaysAgo)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get missed calls
  Future<List<Call>> getMissedCalls({int limit = 20}) async {
    try {
      return await execute(
        status: 'missed',
        limit: limit,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get completed calls
  Future<List<Call>> getCompletedCalls({int limit = 20}) async {
    try {
      return await execute(
        status: 'ended',
        limit: limit,
      );
    } catch (e) {
      rethrow;
    }
  }
}