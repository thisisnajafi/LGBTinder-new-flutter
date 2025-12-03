import '../../data/repositories/safety_repository.dart';

/// Use case for adding a user to favorites
class AddToFavoritesUseCase {
  final SafetyRepository _repository;

  AddToFavoritesUseCase(this._repository);

  /// Execute add to favorites use case
  Future<FavoriteUser> execute(AddFavoriteRequest request) async {
    try {
      return await _repository.addToFavorites(request);
    } catch (e) {
      rethrow;
    }
  }
}
