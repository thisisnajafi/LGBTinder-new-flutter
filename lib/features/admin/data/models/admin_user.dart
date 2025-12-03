/// Admin user model for managing admin users
class AdminUser {
  final int id;
  final String email;
  final String name;
  final String role; // 'super_admin', 'admin', 'moderator'
  final List<String> permissions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final Map<String, dynamic> metadata;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
    required this.isActive,
    required this.createdAt,
    required this.lastLoginAt,
    required this.metadata,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      permissions: json['permissions'] != null
          ? (json['permissions'] as List).map((e) => e.toString()).toList()
          : [],
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : DateTime.now(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'permissions': permissions,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Check if user has a specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission) || role == 'super_admin';
  }

  /// Check if user is super admin
  bool get isSuperAdmin => role == 'super_admin';

  /// Check if user is admin or higher
  bool get isAdmin => ['super_admin', 'admin'].contains(role);

  /// Check if user is moderator or higher
  bool get isModerator => ['super_admin', 'admin', 'moderator'].contains(role);

  /// Get role display name
  String get roleDisplayName {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderator';
      default:
        return role;
    }
  }
}

/// Admin user creation request
class CreateAdminUserRequest {
  final String email;
  final String name;
  final String password;
  final String role;
  final List<String> permissions;

  CreateAdminUserRequest({
    required this.email,
    required this.name,
    required this.password,
    required this.role,
    required this.permissions,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'password': password,
      'role': role,
      'permissions': permissions,
    };
  }
}

/// Admin user update request
class UpdateAdminUserRequest {
  final int id;
  final String? email;
  final String? name;
  final String? role;
  final List<String>? permissions;
  final bool? isActive;

  UpdateAdminUserRequest({
    required this.id,
    this.email,
    this.name,
    this.role,
    this.permissions,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (email != null) data['email'] = email;
    if (name != null) data['name'] = name;
    if (role != null) data['role'] = role;
    if (permissions != null) data['permissions'] = permissions;
    if (isActive != null) data['is_active'] = isActive;
    return data;
  }
}
