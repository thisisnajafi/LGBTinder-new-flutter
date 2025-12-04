import '../../data/repositories/call_repository.dart';
import '../../data/models/call.dart';
import '../../data/models/call_action_request.dart';

/// Use Case: AcceptCallUseCase
/// Handles accepting incoming calls
class AcceptCallUseCase {
  final CallRepository _callRepository;

  AcceptCallUseCase(this._callRepository);

  /// Execute accept call use case
  /// Returns [Call] with accepted call details
  Future<Call> execute(CallActionRequest request) async {
    try {
      // Validate request
      if (request.callId.isEmpty) {
        throw Exception('Call ID is required');
      }

      if (request.action != 'accept') {
        throw Exception('Invalid action for accept call use case');
      }

      return await _callRepository.acceptCall(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}