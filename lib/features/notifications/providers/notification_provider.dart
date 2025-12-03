// Provider: Notificationprovider
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotificationproviderProvider = StateNotifierProvider<NotificationproviderNotifier, NotificationproviderState>((ref) {
  return NotificationproviderNotifier();
});

class NotificationproviderState {
  // TODO: Add state properties
}

class NotificationproviderNotifier extends StateNotifier<NotificationproviderState> {
  NotificationproviderNotifier() : super(NotificationproviderState());
  
  // TODO: Implement state management methods
}
