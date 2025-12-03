// Provider: Chatprovider
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ChatproviderProvider = StateNotifierProvider<ChatproviderNotifier, ChatproviderState>((ref) {
  return ChatproviderNotifier();
});

class ChatproviderState {
  // TODO: Add state properties
}

class ChatproviderNotifier extends StateNotifier<ChatproviderState> {
  ChatproviderNotifier() : super(ChatproviderState());
  
  // TODO: Implement state management methods
}
