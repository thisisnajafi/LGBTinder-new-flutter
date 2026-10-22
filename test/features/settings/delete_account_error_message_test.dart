import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/settings/presentation/screens/delete_account_screen.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';

void main() {
  group('deleteAccountErrorMessage', () {
    test('401 becomes a friendly incorrect password message', () {
      final msg = deleteAccountErrorMessage(
        ApiError(code: 401, message: 'Invalid password'),
      );
      expect(msg, 'Incorrect password. Please try again.');
    });

    test('"Invalid password" text without a code is still mapped', () {
      expect(
        deleteAccountErrorMessage(ApiError(message: 'Invalid password')),
        kDeleteAccountWrongPassword,
      );
    });

    test('other errors never leak a raw ApiError string', () {
      final msg = deleteAccountErrorMessage(
        ApiError(code: 500, message: 'SQLSTATE boom'),
      );
      expect(msg, kDeleteAccountGenericError);
      expect(msg.contains('ApiError'), isFalse);
      expect(deleteAccountErrorMessage(Exception('x')), kDeleteAccountGenericError);
    });
  });
}
