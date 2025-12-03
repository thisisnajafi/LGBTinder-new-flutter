import '../../data/repositories/chat_repository.dart';

/// Use case for getting user's chat list
class GetChatsUseCase {
  final ChatRepository _repository;

  GetChatsUseCase(this._repository);

  /// Execute get chats use case
  Future<List<Chat>> execute() async {
    try {
      return await _repository.getChats();
    } catch (e) {
      rethrow;
    }
  }
}
