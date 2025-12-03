import '../../data/repositories/call_repository.dart';
import '../../data/models/call.dart';

/// Use Case: InitiateCallUseCase
/// Handles initiating new voice or video calls
class InitiateCallUseCase {
  final CallRepository _callRepository;

  InitiateCallUseCase(this._callRepository);

  /// Execute initiate call use case
  /// Returns [Call] with initiated call details
  Future<Call> execute(InitiateCallRequest request) async {
    try {
      // Validate call type
      if (!['audio', 'video'].contains(request.callType)) {
        throw Exception('Invalid call type. Must be "audio" or "video"');
      }

      // Check call eligibility first
      final eligibility = await _callRepository.checkCallEligibility(request.receiverId);
      if (!eligibility.canCall) {
        throw Exception(eligibility.reason ?? 'Unable to initiate call');
      }

      return await _callRepository.initiateCall(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}