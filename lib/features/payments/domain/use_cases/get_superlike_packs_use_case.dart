import '../../data/repositories/payment_repository.dart';

/// Use case for getting available superlike packs
class GetSuperlikePacksUseCase {
  final PaymentRepository _repository;

  GetSuperlikePacksUseCase(this._repository);

  /// Execute get superlike packs use case
  Future<List<SuperlikePack>> execute() async {
    try {
      return await _repository.getSuperlikePacks();
    } catch (e) {
      rethrow;
    }
  }
}
