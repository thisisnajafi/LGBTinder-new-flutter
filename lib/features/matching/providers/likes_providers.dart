import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../data/services/likes_service.dart';

/// Likes Service Provider
final likesServiceProvider = Provider<LikesService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return LikesService(apiService);
});

