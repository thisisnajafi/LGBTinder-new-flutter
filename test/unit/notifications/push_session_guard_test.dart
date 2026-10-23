import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/shared/services/push_session_guard.dart';

void main() {
  group('PushSessionGuard', () {
    test('no session when token missing', () async {
      PushSessionGuard.readAuthToken = () async => null;
      expect(await PushSessionGuard.hasLocalSession(), isFalse);
    });

    test('no session when token empty', () async {
      PushSessionGuard.readAuthToken = () async => '';
      expect(await PushSessionGuard.hasLocalSession(), isFalse);
    });

    test('no session when storage throws', () async {
      PushSessionGuard.readAuthToken = () async => throw Exception('locked');
      expect(await PushSessionGuard.hasLocalSession(), isFalse);
    });

    test('session when token present', () async {
      PushSessionGuard.readAuthToken = () async => 'abc';
      expect(await PushSessionGuard.hasLocalSession(), isTrue);
    });
  });
}
