// Provider: Onboardingprovider
import 'package:flutter_riverpod/flutter_riverpod.dart';

final OnboardingproviderProvider = StateNotifierProvider<OnboardingproviderNotifier, OnboardingproviderState>((ref) {
  return OnboardingproviderNotifier();
});

class OnboardingproviderState {
  // TODO: Add state properties
}

class OnboardingproviderNotifier extends StateNotifier<OnboardingproviderState> {
  OnboardingproviderNotifier() : super(OnboardingproviderState());
  
  // TODO: Implement state management methods
}
