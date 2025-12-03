// Provider: Analyticsprovider
import 'package:flutter_riverpod/flutter_riverpod.dart';

final AnalyticsproviderProvider = StateNotifierProvider<AnalyticsproviderNotifier, AnalyticsproviderState>((ref) {
  return AnalyticsproviderNotifier();
});

class AnalyticsproviderState {
  // TODO: Add state properties
}

class AnalyticsproviderNotifier extends StateNotifier<AnalyticsproviderState> {
  AnalyticsproviderNotifier() : super(AnalyticsproviderState());
  
  // TODO: Implement state management methods
}
