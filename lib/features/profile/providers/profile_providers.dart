import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../data/services/profile_service.dart';
import '../data/services/image_service.dart';
import '../data/models/user_profile.dart';

/// Profile Service Provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProfileService(apiService);
});

/// Image Service Provider
final imageServiceProvider = Provider<ImageService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ImageService(apiService);
});

/// My Profile Provider (current user's profile)
final myProfileProvider = FutureProvider<UserProfile?>((ref) async {
  try {
    final service = ref.watch(profileServiceProvider);
    return await service.getMyProfile();
  } catch (e) {
    // Return null if profile doesn't exist or user is not authenticated
    return null;
  }
});

