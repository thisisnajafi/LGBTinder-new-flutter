import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/config/agora_config.dart';
import 'package:lgbtindernew/features/calls/data/services/call_signaling_service.dart';

void main() {
  test('AgoraConfig does not ship a bundled App ID', () {
    expect(AgoraConfig.appId, isEmpty);
  });

  test('resolveAppId prefers the token endpoint', () {
    expect(AgoraConfig.resolveAppId('  endpoint-id  '), 'endpoint-id');
    expect(AgoraConfig.resolveAppId(''), AgoraConfig.appId);
    expect(AgoraConfig.resolveAppId(null), AgoraConfig.appId);
    expect(AgoraConfig.hasAppId('endpoint-id'), isTrue);
    expect(AgoraConfig.hasAppId(''), isFalse);
  });

  test('AgoraTokenData reads app_id and treats blanks as missing', () {
    final withId = AgoraTokenData.fromJson({
      'token': 'tok',
      'channel_name': 'ch',
      'uid': 7,
      'expires_at': '2026-09-11T12:00:00Z',
      'app_id': '  from-api  ',
    });
    expect(withId.appId, 'from-api');
    expect(AgoraConfig.resolveAppId(withId.appId), 'from-api');

    final blank = AgoraTokenData.fromJson({
      'token': 'tok',
      'channel_name': 'ch',
      'uid': 7,
      'app_id': '  ',
    });
    expect(blank.appId, isNull);
  });
}
