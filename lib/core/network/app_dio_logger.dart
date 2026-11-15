import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/app_logger.dart';
import 'dio_client.dart' show redactSensitiveBody, redactSensitiveUrl;

/// Dio interceptor that logs requests, responses, and errors via [AppLogger].
///
/// Bodies and URLs go through the same redaction as [DioClient] so a
/// password / token can never be printed, whichever logger a Dio uses.
class AppDioLogger extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.apiRequest(
      options.method,
      redactSensitiveUrl(options.path),
      body: options.data is Map
          ? redactSensitiveBody(options.data as Map)
          : null,
    );
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.apiResponse(
      response.requestOptions.method,
      redactSensitiveUrl(response.requestOptions.path),
      response.statusCode ?? 0,
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final path = redactSensitiveUrl(err.requestOptions.path);
    AppLogger.error(
      'API error: ${err.requestOptions.method} $path',
      tag: 'Dio',
      error: '${err.response?.statusCode} — ${err.message}',
    );
    if (kDebugMode && err.response != null) {
      final data = err.response?.data;
      AppLogger.error(
        'Response body: ${data is Map ? redactSensitiveBody(data) : data}',
        tag: 'Dio',
      );
    }
    super.onError(err, handler);
  }
}
