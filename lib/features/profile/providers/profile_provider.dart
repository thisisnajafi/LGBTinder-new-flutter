// Provider: Profileprovider
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ProfileproviderProvider = StateNotifierProvider<ProfileproviderNotifier, ProfileproviderState>((ref) {
  return ProfileproviderNotifier();
});

class ProfileproviderState {
  // TODO: Add state properties
}

class ProfileproviderNotifier extends StateNotifier<ProfileproviderState> {
  ProfileproviderNotifier() : super(ProfileproviderState());
  
  // TODO: Implement state management methods
}
