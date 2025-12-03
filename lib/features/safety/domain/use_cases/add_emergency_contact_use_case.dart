import '../../data/repositories/safety_repository.dart';
import '../../data/models/emergency_contact.dart';

/// Use Case: AddEmergencyContactUseCase
/// Handles adding emergency contacts for safety features
class AddEmergencyContactUseCase {
  final SafetyRepository _safetyRepository;

  AddEmergencyContactUseCase(this._safetyRepository);

  /// Execute add emergency contact use case
  /// Returns [EmergencyContact] with contact details
  Future<EmergencyContact> execute(AddEmergencyContactRequest request) async {
    try {
      return await _safetyRepository.addEmergencyContact(request);
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
