// Provider: Matchingprovider
import 'package:flutter_riverpod/flutter_riverpod.dart';

final MatchingproviderProvider = StateNotifierProvider<MatchingproviderNotifier, MatchingproviderState>((ref) {
  return MatchingproviderNotifier();
});

class MatchingproviderState {
  // TODO: Add state properties
}

class MatchingproviderNotifier extends StateNotifier<MatchingproviderState> {
  MatchingproviderNotifier() : super(MatchingproviderState());
  
  // TODO: Implement state management methods
}
