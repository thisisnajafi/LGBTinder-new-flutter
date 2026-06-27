import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/providers/api_providers.dart';
import 'package:lgbtindernew/core/services/presence_service.dart';
import 'package:lgbtindernew/features/chat/data/repositories/chat_repository.dart';
import 'package:lgbtindernew/features/chat/data/services/chat_service.dart';
import 'package:lgbtindernew/features/chat/providers/chat_providers.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/shared/services/session_api_service.dart';

class _TrackingChatRepository extends ChatRepository {
  _TrackingChatRepository(this.onlineCalls) : super(ChatService(_NoopApiService()));

  final List<bool> onlineCalls;

  @override
  Future<void> setOnlineStatus(bool isOnline) async {
    onlineCalls.add(isOnline);
  }
}

class _TrackingSessionApiService extends SessionApiService {
  _TrackingSessionApiService(this.onActivity) : super(_NoopApiService());

  final void Function() onActivity;

  @override
  Future<void> reportActivity({String? sessionId}) async {
    onActivity();
  }
}

class _NoopApiService extends ApiService {
  _NoopApiService() : super(null);
}

void main() {
  group('PresenceService lifecycle', () {
    test('onForeground marks online and reports session activity', () async {
      final onlineCalls = <bool>[];
      var activityReports = 0;

      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWith(
            (ref) => _TrackingChatRepository(onlineCalls),
          ),
          sessionApiServiceProvider.overrideWith(
            (ref) => _TrackingSessionApiService(() => activityReports++),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(presenceServiceProvider);
      await service.onForeground();

      expect(onlineCalls, [true]);
      expect(activityReports, 1);
    });

    test('onBackground marks offline and stops heartbeat', () async {
      final onlineCalls = <bool>[];
      var activityReports = 0;

      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWith(
            (ref) => _TrackingChatRepository(onlineCalls),
          ),
          sessionApiServiceProvider.overrideWith(
            (ref) => _TrackingSessionApiService(() => activityReports++),
          ),
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
