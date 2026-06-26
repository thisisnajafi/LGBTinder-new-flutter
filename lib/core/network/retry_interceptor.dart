import 'package:dio/dio.dart';

import '../services/app_logger.dart';
import '../services/connectivity_service.dart';

/// Automatically retries transient network failures with exponential backoff.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio);

  final Dio _dio;

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  static bool _isRetryable(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.response?.statusCode == 503) ||
        (error.response?.statusCode == 429 && _isRateLimitRetryable(error));
  }

  static bool _isFinalError(DioException error) {
    final status = error.response?.statusCode;
    return status == 400 ||
        status == 401 ||
        status == 403 ||
        status == 404 ||
        status == 422;
  }

  static bool _isRateLimitRetryable(DioException error) {
    return error.response?.headers.value('retry-after') != null;
  }

  int _maxRetriesFor(DioException error) {
    return error.requestOptions.extra['_maxRetries'] as int? ?? _maxRetries;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = err.requestOptions.extra['_retryCount'] as int? ?? 0;
    final maxRetries = _maxRetriesFor(err);

    if (_isFinalError(err)) {
      AppLogger.warning(
        'Non-retryable error ${err.response?.statusCode}: '
        '${err.requestOptions.method} ${err.requestOptions.path}',
        tag: 'Retry',
      );
      return handler.next(err);
    }

    if (!_isRetryable(err) || attempt >= maxRetries) {
      if (attempt >= maxRetries) {
        AppLogger.warning(
          'Max retries ($attempt/$maxRetries) reached: '
          '${err.requestOptions.method} ${err.requestOptions.path}',
          tag: 'Retry',
        );
        ConnectivityService.instance.markWeakConnection();
      }
      return handler.next(err);
    }

    final delay = _retryDelay * (1 << attempt);

    final retryAfterHeader = err.response?.headers.value('retry-after');
    final actualDelay = retryAfterHeader != null
        ? Duration(
            seconds: int.tryParse(retryAfterHeader) ?? delay.inSeconds,
          )
        : delay;

    AppLogger.info(
      'Retrying (${attempt + 1}/$maxRetries) in ${actualDelay.inSeconds}s: '
      '${err.requestOptions.method} ${err.requestOptions.path}',
      tag: 'Retry',
    );

    await Future.delayed(actualDelay);

    final options = err.requestOptions;
    options.extra['_retryCount'] = attempt + 1;

    try {
      final response = await _dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }
}
