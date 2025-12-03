import '../../data/repositories/safety_repository.dart';

/// Use case for removing a user from favorites
class RemoveFromFavoritesUseCase {
  final SafetyRepository _repository;

  RemoveFromFavoritesUseCase(this._repository);

  /// Execute remove from favorites use case
  Future<void> execute(int favoriteUserId) async {
    try {
      return await _repository.removeFromFavorites(favoriteUserId);
    } catch (e) {
      rethrow;
    }
  }
}
