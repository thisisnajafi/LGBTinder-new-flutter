// Provider: Discoveryprovider
import 'package:flutter_riverpod/flutter_riverpod.dart';

final DiscoveryproviderProvider = StateNotifierProvider<DiscoveryproviderNotifier, DiscoveryproviderState>((ref) {
  return DiscoveryproviderNotifier();
});

class DiscoveryproviderState {
  // TODO: Add state properties
}

class DiscoveryproviderNotifier extends StateNotifier<DiscoveryproviderState> {
  DiscoveryproviderNotifier() : super(DiscoveryproviderState());
  
  // TODO: Implement state management methods
}
