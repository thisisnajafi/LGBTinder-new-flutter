import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/config/pusher_config.dart';
import 'package:lgbtindernew/core/services/connectivity_service.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/chat/utils/chat_media_permissions.dart';
import 'package:lgbtindernew/widgets/chat/chat_voice_record_bar.dart';

void main() {
  test('failed probes are offline, not a weak link that still sends', () {
    expect(
      ConnectivityService.classify(hasInterface: false, hasInternet: false),
      NetworkConnectionState.disconnected,
    );
    expect(
      ConnectivityService.classify(hasInterface: true, hasInternet: false),
      NetworkConnectionState.disconnected,
    );
    expect(
      ConnectivityService.classify(hasInterface: true, hasInternet: true),
      NetworkConnectionState.connected,
    );
  });

  test('Android 13 photo picker is not blocked on a storage grant', () {
    expect(
      ChatMediaPermissions.usesSystemPhotoPicker(
        isAndroid: true,
        androidSdk: 34,
        kind: ChatMediaPermissionKind.photos,
      ),
      isTrue,
    );
    expect(
      ChatMediaPermissions.usesSystemPhotoPicker(
        isAndroid: true,
        androidSdk: 28,
        kind: ChatMediaPermissionKind.photos,
      ),
      isFalse,
    );
    expect(
      ChatMediaPermissions.usesSystemPhotoPicker(
        isAndroid: true,
        androidSdk: 34,
        kind: ChatMediaPermissionKind.camera,
      ),
      isFalse,
    );
  });

  test('local realtime config replaces cluster DNS', () {
    PusherConfig.resetRuntime();
    PusherConfig.applyRemote(
      key: 'local-lgbtinder-key',
      cluster: 'mt1',
      host: '10.0.2.2',
      port: 8090,
      useTls: false,
      updateEndpoint: true,
    );
    expect(PusherConfig.host, '10.0.2.2');
    expect(PusherConfig.wsPort, 8090);
    expect(PusherConfig.useTls, isFalse);
    expect(
      PusherConfig.connectionIdentity,
      'local-lgbtinder-key|mt1|10.0.2.2|8090|false',
    );

    PusherConfig.applyRemote(
      key: 'cloud-key',
      cluster: 'us3',
      updateEndpoint: true,
    );
    expect(PusherConfig.host, isNull);
    expect(PusherConfig.useTls, isTrue);
    PusherConfig.resetRuntime();
  });

  testWidgets('voice record bar fits a phone composer width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: ChatVoiceRecordBar(
              seconds: 4,
              locked: false,
              compact: true,
              onDiscard: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ChatVoiceRecordBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
