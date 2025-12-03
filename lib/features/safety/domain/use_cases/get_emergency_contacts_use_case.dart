import '../../data/repositories/safety_repository.dart';

/// Use case for getting emergency contacts
class GetEmergencyContactsUseCase {
  final SafetyRepository _repository;

  GetEmergencyContactsUseCase(this._repository);

  /// Execute get emergency contacts use case
  Future<List<EmergencyContact>> execute() async {
    try {
      return await _repository.getEmergencyContacts();
    } catch (e) {
      rethrow;
    }
  }
}
