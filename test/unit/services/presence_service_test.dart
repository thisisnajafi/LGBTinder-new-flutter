import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/providers/api_providers.dart';
import 'package:lgbtindernew/core/services/presence_service.dart';
import 'package:lgbtindernew/features/chat/data/repositories/chat_repository.dart';
import 'package:lgbtindernew/features/chat/data/services/chat_service.dart';
import 'package:lgbtindernew/features/chat/providers/chat_providers.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/shared/services/session_api_service.dart';

import 'chat_service_test.mocks.dart';

class _TrackingChatRepository extends ChatRepository {
  _TrackingChatRepository(this.onlineCalls, ChatService service) : super(service);

  final List<bool> onlineCalls;

  @override
  Future<void> setOnlineStatus(bool isOnline) async {
    onlineCalls.add(isOnline);
  }
}

class _TrackingSessionApiService extends SessionApiService {
  _TrackingSessionApiService(this.onActivity, ApiService apiService) : super(apiService);

  final void Function() onActivity;

  @override
  Future<void> reportActivity({String? sessionId}) async {
    onActivity();
  }
}

void main() {
  group('PresenceService lifecycle', () {
    test('onForeground marks online and reports session activity', () async {
      final onlineCalls = <bool>[];
      var activityReports = 0;
      final mockApi = MockApiService();
      final chatRepo = _TrackingChatRepository(onlineCalls, ChatService(mockApi));
      final sessionApi = _TrackingSessionApiService(() => activityReports++, mockApi);

      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(chatRepo),
          sessionApiServiceProvider.overrideWithValue(sessionApi),
        ],
      );
      addTearDown(container.dispose);

      await container.read(presenceServiceProvider).onForeground();

      expect(onlineCalls, [true]);
      expect(activityReports, 1);
    });

    test('onBackground marks offline and stops heartbeat', () async {
      final onlineCalls = <bool>[];
      var activityReports = 0;
      final mockApi = MockApiService();
      final chatRepo = _TrackingChatRepository(onlineCalls, ChatService(mockApi));
      final sessionApi = _TrackingSessionApiService(() => activityReports++, mockApi);

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

      expect(onlineCalls, [true, false]);

      activityReports = 0;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(activityReports, 0);
    });
  });
}
