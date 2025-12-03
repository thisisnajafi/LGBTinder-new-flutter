import '../../data/repositories/admin_repository.dart';
import '../../data/models/admin_user.dart';

/// Use Case: ManageAdminUsersUseCase
/// Handles admin user management operations
class ManageAdminUsersUseCase {
  final AdminRepository _adminRepository;

  ManageAdminUsersUseCase(this._adminRepository);

  /// Get all admin users
  Future<List<AdminUser>> getAdminUsers({
    int? page,
    int? limit,
    String? role,
    bool? isActive,
  }) async {
    try {
      return await _adminRepository.getAdminUsers(
        page: page,
        limit: limit,
        role: role,
        isActive: isActive,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get admin user by ID
  Future<AdminUser> getAdminUser(int id) async {
    try {
      return await _adminRepository.getAdminUser(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Create new admin user
  Future<AdminUser> createAdminUser(CreateAdminUserRequest request) async {
    try {
      // Validate request
      if (request.email.isEmpty || request.name.isEmpty || request.password.isEmpty) {
        throw Exception('All fields are required');
      }

      if (request.password.length < 8) {
        throw Exception('Password must be at least 8 characters long');
      }

      if (!['super_admin', 'admin', 'moderator'].contains(request.role)) {
        throw Exception('Invalid role specified');
      }

      return await _adminRepository.createAdminUser(request);
    } catch (e) {
      rethrow;
    }
  }

  /// Update admin user
  Future<AdminUser> updateAdminUser(UpdateAdminUserRequest request) async {
    try {
      // Validate request
      if (request.email != null && request.email!.isEmpty) {
        throw Exception('Email cannot be empty');
      }

      if (request.name != null && request.name!.isEmpty) {
        throw Exception('Name cannot be empty');
      }

      if (request.role != null && !['super_admin', 'admin', 'moderator'].contains(request.role)) {
        throw Exception('Invalid role specified');
      }

      return await _adminRepository.updateAdminUser(request);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete admin user
  Future<void> deleteAdminUser(int id) async {
    try {
      await _adminRepository.deleteAdminUser(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle admin user active status
  Future<AdminUser> toggleUserStatus(int id, bool isActive) async {
    try {
      final request = UpdateAdminUserRequest(id: id, isActive: isActive);
      return await _adminRepository.updateAdminUser(request);
    } catch (e) {
      rethrow;
    }
  }
}
