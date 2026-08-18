import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/providers/api_providers.dart';
import 'package:lgbtindernew/core/providers/own_presence_provider.dart';
import 'package:lgbtindernew/core/services/presence_service.dart';
import 'package:lgbtindernew/features/chat/data/repositories/chat_repository.dart';
import 'package:lgbtindernew/features/chat/providers/chat_providers.dart';
import 'package:lgbtindernew/shared/services/session_api_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockSessionApiService extends Mock implements SessionApiService {}

void main() {
  group('PresenceService lifecycle', () {
    test('onForeground marks online and reports session activity', () async {
      final chatRepo = _MockChatRepository();
      final sessionApi = _MockSessionApiService();

      when(() => chatRepo.setOnlineStatus(true)).thenAnswer((_) async {});
      when(() => sessionApi.reportActivity()).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(chatRepo),
          sessionApiServiceProvider.overrideWithValue(sessionApi),
        ],
      );
      addTearDown(container.dispose);

      await container.read(presenceServiceProvider).onForeground();

      verify(() => chatRepo.setOnlineStatus(true)).called(1);
      verify(() => sessionApi.reportActivity()).called(1);
      expect(container.read(ownPresenceProvider), isTrue);
    });

    test('onBackground marks offline and stops heartbeat', () async {
      final chatRepo = _MockChatRepository();
      final sessionApi = _MockSessionApiService();

      when(() => chatRepo.setOnlineStatus(any())).thenAnswer((_) async {});
      when(() => sessionApi.reportActivity()).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(chatRepo),
          sessionApiServiceProvider.overrideWithValue(sessionApi),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(presenceServiceProvider);
      await service.onForeground();
      await service.onBackground();

      verifyInOrder([
        () => chatRepo.setOnlineStatus(true),
        () => chatRepo.setOnlineStatus(false),
      ]);
      expect(container.read(ownPresenceProvider), isFalse);
    });
  });
}
