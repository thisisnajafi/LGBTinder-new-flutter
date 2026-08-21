import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/auth/banned_handler.dart';
import 'package:lgbtindernew/core/network/dio_client.dart';
import 'package:lgbtindernew/shared/services/token_storage_service.dart';

void main() {
  late DioClient dioClient;
  late _FakeTokenStorage tokens;

  setUp(() {
    tokens = _FakeTokenStorage();
    dioClient = DioClient(tokens);
  });

  group('DioClient 4xx semantics (C-1)', () {
    test('validateStatus accepts 2xx only', () {
      final validate = dioClient.dio.options.validateStatus;
      expect(validate(200), isTrue);
      expect(validate(201), isTrue);
      expect(validate(204), isTrue);
      expect(validate(400), isFalse);
      expect(validate(401), isFalse);
      expect(validate(403), isFalse);
      expect(validate(422), isFalse);
      expect(validate(429), isFalse);
      expect(validate(500), isFalse);
    });

    test('403 plan denial does not invoke BannedHandler', () async {
      var banned = false;
      BannedHandler.setCallback(() => banned = true);

      dioClient.dio.httpClientAdapter = _StatusAdapter(
        403,
        {
          'error_code': 'PREMIUM_REQUIRED',
          'message': 'Upgrade required',
        },
      );

      try {
        await dioClient.dio.get('/likes/matches');
        fail('403 must throw DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 403);
      }

      expect(banned, isFalse);
    });

    test('403 banned payload invokes BannedHandler via onError', () async {
      var banned = false;
      BannedHandler.setCallback(() => banned = true);

      dioClient.dio.httpClientAdapter = _StatusAdapter(
        403,
        {
          'error': true,
          'message': 'Your account has been banned.',
          'data': {
            'user_state': 'banned',
            'banned': true,
          },
        },
      );

      try {
        await dioClient.dio.get('/discover');
        fail('403 must throw DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 403);
      }

      expect(banned, isTrue);
    });

    test('429 is a DioException so RetryInterceptor can see it', () async {
      dioClient.dio.httpClientAdapter = _StatusAdapter(429, {
        'message': 'Too many requests',
      });

      try {
        await dioClient.dio.get('/discover');
        fail('429 must throw DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 429);
        expect(e.type, DioExceptionType.badResponse);
      }
    });
  });
}

class _FakeTokenStorage extends Fake implements TokenStorageService {
  @override
  Future<String?> getAuthToken() async => 'tok';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
