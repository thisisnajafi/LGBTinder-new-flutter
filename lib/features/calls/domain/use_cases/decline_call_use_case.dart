import '../../data/models/call_action_request.dart';
import '../../data/repositories/call_repository.dart';

/// Handles rejecting an incoming call.
class DeclineCallUseCase {
  DeclineCallUseCase(this._callRepository);

  final CallRepository _callRepository;

  Future<void> execute(CallActionRequest request) async {
    if (request.callId.isEmpty) {
      throw Exception('Call ID is required');
    }
    if (request.action != 'reject') {
      throw Exception('Invalid action for decline call use case');
    }
    await _callRepository.declineCall(request);
  }
}
