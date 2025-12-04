import '../../data/repositories/call_repository.dart';
import '../../data/models/call.dart';

/// Use Case: GetCallUseCase
/// Handles retrieving a specific call by ID
class GetCallUseCase {
  final CallRepository _callRepository;

  GetCallUseCase(this._callRepository);

  /// Execute get call use case
  /// Returns [Call] with the specified call details
  Future<Call> execute(String callId) async {
    try {
      // Validate callId
      if (callId.isEmpty) {
        throw Exception('Call ID cannot be empty');
      }

      final call = await _callRepository.getCall(callId);

      return call;
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
