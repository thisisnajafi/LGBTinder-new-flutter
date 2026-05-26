import 'package:dio/dio.dart';

import '../services/app_logger.dart';

/// Dio interceptor that logs requests, responses, and errors via [AppLogger].
class AppDioLogger extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.apiRequest(
      options.method,
      options.path,
      body: options.data is Map ? options.data as Map : null,
    );
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.apiResponse(
      response.requestOptions.method,
      response.requestOptions.path,
      response.statusCode ?? 0,
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      'API error: ${err.requestOptions.method} ${err.requestOptions.path}',
      tag: 'Dio',
      error: '${err.response?.statusCode} — ${err.message}',
    );
    if (err.response != null) {
      AppLogger.error(
        'Response body: ${err.response?.data}',
        tag: 'Dio',
      );
    }
    super.onError(err, handler);
  }
}
