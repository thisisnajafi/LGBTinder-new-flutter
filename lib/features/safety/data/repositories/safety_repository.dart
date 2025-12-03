import '../../domain/services/user_actions_service.dart';
import '../models/block.dart';
import '../models/report.dart';
import '../models/favorite.dart';
import '../models/emergency_contact.dart';

/// Safety repository - wraps UserActionsService for use in use cases
class SafetyRepository {
  final UserActionsService _userActionsService;

  SafetyRepository(this._userActionsService);

  /// Block a user
  Future<BlockedUser> blockUser(BlockUserRequest request) async {
    return await _userActionsService.blockUser(request);
  }

  /// Unblock a user
  Future<void> unblockUser(int blockedUserId) async {
    return await _userActionsService.unblockUser(blockedUserId);
  }

  /// Get blocked users list
  Future<List<BlockedUser>> getBlockedUsers() async {
    return await _userActionsService.getBlockedUsers();
  }

  /// Report a user
  Future<Report> reportUser(ReportUserRequest request) async {
    return await _userActionsService.reportUser(request);
  }

  /// Get user's reports history
  Future<List<Report>> getReportsHistory() async {
    return await _userActionsService.getReportsHistory();
  }

  /// Add user to favorites
  Future<FavoriteUser> addToFavorites(AddFavoriteRequest request) async {
    return await _userActionsService.addToFavorites(request);
  }

  /// Remove user from favorites
  Future<void> removeFromFavorites(int favoriteUserId) async {
    return await _userActionsService.removeFromFavorites(favoriteUserId);
  }

  /// Get favorites list
  Future<List<FavoriteUser>> getFavorites() async {
    return await _userActionsService.getFavorites();
  }

  /// Add emergency contact
  Future<EmergencyContact> addEmergencyContact(AddEmergencyContactRequest request) async {
    return await _userActionsService.addEmergencyContact(request);
  }

  /// Update emergency contact
  Future<EmergencyContact> updateEmergencyContact(UpdateEmergencyContactRequest request) async {
    return await _userActionsService.updateEmergencyContact(request);
  }

  /// Remove emergency contact
  Future<void> removeEmergencyContact(int contactId) async {
    return await _userActionsService.removeEmergencyContact(contactId);
  }

  /// Get emergency contacts
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    return await _userActionsService.getEmergencyContacts();
  }

  /// Send emergency alert
  Future<EmergencyAlert> sendEmergencyAlert(SendEmergencyAlertRequest request) async {
    return await _userActionsService.sendEmergencyAlert(request);
  }
}
