import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_providers.dart';
import '../data/repositories/call_repository.dart';
import '../data/services/call_service.dart';
import '../domain/use_cases/accept_call_use_case.dart';
import '../domain/use_cases/decline_call_use_case.dart';
import '../domain/use_cases/end_call_use_case.dart';
import '../domain/use_cases/get_call_history_use_case.dart';
import '../domain/use_cases/get_call_use_case.dart';
import '../domain/use_cases/initiate_call_use_case.dart';

final callServiceProvider = Provider<CallService>((ref) {
  return CallService(ref.watch(apiServiceProvider));
});

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepository(ref.watch(callServiceProvider));
});

final initiateCallUseCaseProvider = Provider<InitiateCallUseCase>((ref) {
  return InitiateCallUseCase(ref.watch(callRepositoryProvider));
});

final getCallHistoryUseCaseProvider = Provider<GetCallHistoryUseCase>((ref) {
  return GetCallHistoryUseCase(ref.watch(callRepositoryProvider));
});

final getCallUseCaseProvider = Provider<GetCallUseCase>((ref) {
  return GetCallUseCase(ref.watch(callRepositoryProvider));
});

final acceptCallUseCaseProvider = Provider<AcceptCallUseCase>((ref) {
  return AcceptCallUseCase(ref.watch(callRepositoryProvider));
});

final endCallUseCaseProvider = Provider<EndCallUseCase>((ref) {
  return EndCallUseCase(ref.watch(callRepositoryProvider));
});

final declineCallUseCaseProvider = Provider<DeclineCallUseCase>((ref) {
  return DeclineCallUseCase(ref.watch(callRepositoryProvider));
});
