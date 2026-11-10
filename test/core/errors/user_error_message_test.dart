import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/errors/user_error_message.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';

DioException _bad(int status, Object? data) {
  final req = RequestOptions(path: '/api/x');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: req, statusCode: status, data: data),
  );
}

void main() {
  test('hides technical exception text', () {
    expect(userErrorMessage(StateError('Bad state: x')), kGenericErrorMessage);
    expect(userErrorMessage(Exception('type \'Null\' is not a subtype of String')),
        kGenericErrorMessage);
    expect(userErrorMessage('SQLSTATE[23000]: Integrity constraint'),
        kGenericErrorMessage);
    expect(userErrorMessage('https://api.lgbtfinder.com/api/x failed'),
        kGenericErrorMessage);
    expect(userErrorMessage('{"message":"Server Error"}'), kGenericErrorMessage);
    expect(userErrorMessage('#0 main (package:x/y.dart:1:2)'),
        kGenericErrorMessage);
  });

  test('keeps user-safe messages', () {
    expect(userErrorMessage(Exception('Wrong email or password')),
        'Wrong email or password');
    expect(userErrorMessage(const SocketException('x')), kNoInternetMessage);
    expect(userErrorMessage(TimeoutException('x')), kTimeoutMessage);
  });

  test('500 from API is always generic', () {
    final e = _bad(500, {'message': 'SQLSTATE[42S22]: Column not found', 'trace': []});
    expect(userErrorMessage(e), kGenericErrorMessage);
    expect(ApiError.fromDioException(e).message, kGenericErrorMessage);
  });

  test('422 validation message is kept', () {
    final e = _bad(422, {
      'message': 'The email has already been taken.',
      'errors': {
        'email': ['The email has already been taken.']
      }
    });
    expect(userErrorMessage(e), 'The email has already been taken.');
  });

  test('401 login message is kept', () {
    final e = _bad(401, {'message': 'Wrong email or password'});
    expect(userErrorMessage(e), 'Wrong email or password');
  });

  test('plan error code maps to friendly text', () {
    final e = _bad(403, {'message': 'x', 'error_code': 'PREMIUM_REQUIRED'});
    expect(userErrorMessage(e), backendErrorMessages['PREMIUM_REQUIRED']);
  });

  test('unknown Dio error does not leak Dio text', () {
    final e = DioException(
      requestOptions: RequestOptions(path: '/api/x'),
      type: DioExceptionType.unknown,
      message: 'DioException [unknown]: null Error: HttpException: Connection closed, uri = https://api.lgbtfinder.com/api/x',
    );
    expect(userErrorMessage(e), kGenericErrorMessage);
  });
}
