// Provider: Paymentprovider
import 'package:flutter_riverpod/flutter_riverpod.dart';

final PaymentproviderProvider = StateNotifierProvider<PaymentproviderNotifier, PaymentproviderState>((ref) {
  return PaymentproviderNotifier();
});

class PaymentproviderState {
  // TODO: Add state properties
}

class PaymentproviderNotifier extends StateNotifier<PaymentproviderState> {
  PaymentproviderNotifier() : super(PaymentproviderState());
  
  // TODO: Implement state management methods
}
