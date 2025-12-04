import '../../domain/services/matching_service.dart';
import '../models/like.dart';
import '../models/match.dart';
import '../models/superlike.dart';
import '../models/compatibility_score.dart';

/// Matching repository - wraps MatchingService for use in use cases
class MatchingRepository {
  final MatchingService _matchingService;

  MatchingRepository(this._matchingService);

  /// Like a profile
  Future<LikeResponse> likeProfile(int profileId) async {
    return await _matchingService.likeProfile(profileId);
  }

  /// Dislike a profile
  Future<void> dislikeProfile(int profileId) async {
    return await _matchingService.dislikeProfile(profileId);
  }

  /// Superlike a profile
  Future<SuperlikeResponse> superlikeProfile(int profileId) async {
    return await _matchingService.superlikeProfile(profileId);
  }

  /// Get all matches
  Future<List<Match>> getMatches() async {
    return await _matchingService.getMatches();
  }

  /// Get pending likes (likes received from others)
  Future<List<Like>> getPendingLikes() async {
    return await _matchingService.getPendingLikes();
  }

  /// Get superlike history
  Future<List<Superlike>> getSuperlikeHistory() async {
    return await _matchingService.getSuperlikeHistory();
  }

  /// Get compatibility score between current user and target user
  Future<CompatibilityScore> getCompatibilityScore(int targetUserId) async {
    return await _matchingService.getCompatibilityScore(targetUserId);
  }

  Future<bool> checkMatchStatus(int targetUserId) async {
    return await _matchingService.checkMatchStatus(targetUserId);
  }

  /// Respond to a like (accept/reject)
  Future<void> respondToLike(int likeId, bool accept) async {
    return await _matchingService.respondToLike(likeId, accept);
  }

  /// Get match details
  Future<Match> getMatchDetails(int matchId) async {
    return await _matchingService.getMatchDetails(matchId);
  }
}
