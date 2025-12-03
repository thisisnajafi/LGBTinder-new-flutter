import '../../data/repositories/matching_repository.dart';
import '../../data/models/match.dart';

/// Use Case: GetMatchesUseCase
/// Handles retrieving all user matches
class GetMatchesUseCase {
  final MatchingRepository _matchingRepository;

  GetMatchesUseCase(this._matchingRepository);

  /// Execute get matches use case
  /// Returns [List<Match>] with all user matches
  Future<List<Match>> execute() async {
    try {
      return await _matchingRepository.getMatches();
    } catch (e) {
      // Re-throw all exceptions to let UI handle them
      rethrow;
    }
  }
}
