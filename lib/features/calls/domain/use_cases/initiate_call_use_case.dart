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
      if (!['audio', 'video', 'voice'].contains(request.callType)) {
        throw Exception('Invalid call type. Must be "audio", "video", or "voice"');
      }

      final normalized = InitiateCallRequest(
        receiverId: request.receiverId,
        callType: request.callType == 'voice' ? 'audio' : request.callType,
      );

      // Check call eligibility first
      final eligibility = await _callRepository.checkCallEligibility(normalized.receiverId);
      if (!eligibility.canCall) {
        throw Exception(eligibility.reason ?? 'Unable to initiate call');
      }

      return await _callRepository.initiateCall(normalized);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}