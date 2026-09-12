import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/config/pusher_config.dart';
import 'package:lgbtindernew/shared/services/pusher_auth_response.dart';

void main() {
  setUp(PusherConfig.resetRuntime);
  tearDown(PusherConfig.resetRuntime);

  group('PusherAuthResponse.normalize', () {
    test('keeps Laravel auth payload', () {
      expect(
        PusherAuthResponse.normalize({
          'auth': 'abc123:deadbeef',
        }),
        {'auth': 'abc123:deadbeef'},
      );
    });

    test('unwraps unified API envelope and drops extra keys', () {
      expect(
        PusherAuthResponse.normalize({
          'success': true,
          'status': 'success',
          'data': {
            'auth': 'abc123:deadbeef',
            'channel_data': '{"user_id":1}',
            'ignored': true,
          },
        }),
        {
          'auth': 'abc123:deadbeef',
          'channel_data': '{"user_id":1}',
        },
      );
    });

    test('unwraps body envelopes used by some API wrappers', () {
      expect(
        PusherAuthResponse.normalize({
          'body': {
            'auth': 'abc123:deadbeef',
          },
        }),
        {'auth': 'abc123:deadbeef'},
      );
    });

    test('rebuilds auth when the app key is used as the JSON key', () {
      expect(
        PusherAuthResponse.toNativeAuth({
          'e1bc13af2989f44cc18a': 'deadbeefsignature',
        }),
        {'auth': 'e1bc13af2989f44cc18a:deadbeefsignature'},
      );
    });

    test('native auth drops extra keys the Android SDK rejects', () {
      expect(
        PusherAuthResponse.toNativeAuth({
          'auth': 'abc123:deadbeef',
          'e1bc13af2989f44cc18a': 'deadbeef',
          'status': 'success',
        }),
        {'auth': 'abc123:deadbeef'},
      );
    });

    test('reads app key prefix from auth string', () {
      expect(
        PusherAuthResponse.appKeyFromAuth({'auth': 'e1bc13af2989f44cc18a:sig'}),
        'e1bc13af2989f44cc18a',
      );
    });
  });

  test('parses the invalid-key auth error from Android Pusher', () {
    expect(
      PusherConfig.parseKeyFromAuthError(
        "Invalid key in subscription auth data: 'e1bc13af2989f44cc18a'",
      ),
      'e1bc13af2989f44cc18a',
    );
  });
}
