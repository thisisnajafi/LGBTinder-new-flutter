import '../../data/repositories/call_repository.dart';
import '../../data/models/call.dart';
import '../../data/models/call_action_request.dart';

/// Use Case: EndCallUseCase
/// Handles ending active calls
class EndCallUseCase {
  final CallRepository _callRepository;

  EndCallUseCase(this._callRepository);

  /// Execute end call use case
  /// Returns [Call] with ended call details
  Future<Call> execute(CallActionRequest request) async {
    try {
      // Validate request
      if (request.callId.isEmpty) {
        throw Exception('Call ID is required');
      }

      if (request.action != 'end') {
        throw Exception('Invalid action for end call use case');
      }

      return await _callRepository.endCall(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}