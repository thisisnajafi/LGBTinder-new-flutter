import '../../data/repositories/safety_repository.dart';
import '../../data/models/favorite.dart';

/// Use case for getting favorite users
class GetFavoritesUseCase {
  final SafetyRepository _repository;

  GetFavoritesUseCase(this._repository);

  /// Execute get favorites use case
  Future<List<FavoriteUser>> execute() async {
    try {
      return await _repository.getFavorites();
    } catch (e) {
      rethrow;
    }
  }
}
