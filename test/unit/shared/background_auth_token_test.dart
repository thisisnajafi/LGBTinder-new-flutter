import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/shared/services/background_auth_store.dart';

void main() {
  test('background token is used for a killed-app reply', () {
    expect(preferStoredAuthToken('bg-token', 'secure-token'), 'bg-token');
    expect(preferStoredAuthToken(null, 'secure-token'), 'secure-token');
    expect(preferStoredAuthToken('  ', ''), isNull);
  });
}
