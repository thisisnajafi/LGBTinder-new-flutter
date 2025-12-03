import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../data/services/user_service.dart';
import '../data/models/user_info.dart';

/// User Service Provider
final userServiceProvider = Provider<UserService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserService(apiService);
});

/// User Info Provider (FutureProvider for async data)
final userInfoProvider = FutureProvider<UserInfo>((ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getUserInfo();
});

