import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/token_storage_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../auth/banned_handler.dart';
import '../auth/unauthorized_handler.dart';
import '../utils/app_logger.dart';
import 'subscription_meta_interceptor.dart';
import 'retry_interceptor.dart';

/// Max chars of response/request body to log; longer content is truncated.
const int _kLogBodyMaxChars = 400;

/// Request [Options.extra] key: skip token refresh + [UnauthorizedHandler] on 401.
/// Used for best-effort background logout so a late 401 cannot bounce a new session.
const String kSkipUnauthorizedHandlerExtra = 'skipUnauthorizedHandler';

/// Keys redacted from API logs (never print secrets).
const _kRedactedBodyKeys = {
  'password',
  'password_confirmation',
  'token',
  'refresh_token',
  'access_token',
  'id_token',
  'authorization',
  'secret',
  'otp',
};

/// True when a body field / header / query parameter named [key] must never
/// reach the logs: exact matches above plus any `*password*`, `*_token`,
/// `*secret*` or `authorization` variant (`current_password`,
/// `profile_completion_token`, `device_token`, `client_secret`, …).
bool isSensitiveLogKey(String key) {
  final k = key.toLowerCase().replaceAll('-', '_');
  if (_kRedactedBodyKeys.contains(k)) return true;
  if (k.contains('password') || k.contains('secret')) return true;
  if (k.contains('authorization')) return true;
  if (k.endsWith('token') || k.endsWith('_otp')) return true;
  return false;
}

/// Returns a copy of [body] with sensitive fields replaced by `***`
/// (recurses into nested maps and lists).
Map<String, dynamic>? redactSensitiveBody(Map? body) {
  if (body == null || body.isEmpty) return null;
  final out = <String, dynamic>{};
  body.forEach((key, value) {
    final k = key.toString();
    if (isSensitiveLogKey(k)) {
      out[k] = '***';
    } else {
      out[k] = _redactLogValue(value);
    }
  });
  return out;
}

dynamic _redactLogValue(dynamic value) {
  if (value is Map) return redactSensitiveBody(value) ?? value;
  if (value is List) return value.map(_redactLogValue).toList();
  return value;
}

/// Masks sensitive query parameters (`?token=…`) in a logged URL.
String redactSensitiveUrl(String url) {
  final queryStart = url.indexOf('?');
  if (queryStart < 0) return url;
  try {
    final uri = Uri.parse(url);
    if (!uri.queryParametersAll.keys.any(isSensitiveLogKey)) return url;
    final masked = <String, dynamic>{
      for (final entry in uri.queryParametersAll.entries)
        entry.key: isSensitiveLogKey(entry.key) ? '***' : entry.value,
    };
    return uri.replace(queryParameters: masked).toString();
  } catch (_) {
    // Unparseable URL: drop the query rather than risk printing a secret.
    return '${url.substring(0, queryStart)}?***';
  }
}

/// Bearer value of a request's `Authorization` header, if any.
String? _bearerOf(RequestOptions options) {
  final raw = options.headers['Authorization']?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  final value = raw.toLowerCase().startsWith('bearer ')
      ? raw.substring(7).trim()
      : raw;
  return value.isEmpty ? null : value;
}

/// Summarizes response/request body for debug logs (avoids dumping full HTML or huge JSON).
String _summarizeBody(dynamic data, {int maxChars = _kLogBodyMaxChars}) {
  if (data == null) return 'null';
  if (data is Map || data is List) {
    final str = _redactLogValue(data).toString();
    if (str.length <= maxChars) return str;
    return '${str.substring(0, maxChars)}... [${str.length} chars total]';
  }
  final str = data.toString().trim();
  if (str.isEmpty) return '<empty>';
  if (str.length <= maxChars && !_looksLikeHtml(str)) return str;
  if (_looksLikeHtml(str)) {
    final len = str.length;
    final preview = str.length > 120 ? '${str.substring(0, 120)}...' : str;
    return '[HTML/non-JSON, $len chars] preview: $preview';
  }
  if (str.length > maxChars) return '${str.substring(0, maxChars)}... [${str.length} chars]';
  return str;
}

bool _looksLikeHtml(String s) {
  final lower = s.toLowerCase();
  return lower.startsWith('<!doctype') ||
      lower.startsWith('<html') ||
      (lower.contains('<html') && lower.contains('</body>'));
}

/// Dio HTTP client with interceptors for authentication and error handling
class DioClient {
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);

  late final Dio _dio;
  final TokenStorageService _tokenStorage;
  
  // Token refresh state
  bool _isRefreshing = false;
  final List<Completer<void>> _refreshQueue = [];
  String? _refreshedToken;

  DioClient(this._tokenStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // 4xx must be errors so RetryInterceptor (429) and the 401/403
        // onError branch (banned redirect, session expiry) actually run.
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(RetryInterceptor(_dio));

    // Auth, logging, and error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Respect per-request Authorization (e.g. profile completion token).
          final existingAuth = options.headers['Authorization']?.toString();
          if (existingAuth != null && existingAuth.isNotEmpty) {
            options.extra['had_auth_token'] = true;
          } else {
            final token = await _tokenStorage.getAuthToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              options.extra['had_auth_token'] = true;
            }
          }

          // Log request: full URI, body (summarized). Headers are never
          // logged, so the bearer token cannot leak from here.
          final uri = redactSensitiveUrl(options.uri.toString());
          String? requestExtra;
          Map? requestBody;
          if (options.data is FormData) {
            final fd = options.data as FormData;
            requestExtra = '[multipart: ${fd.files.length} file(s)]';
          } else if (options.data is Map) {
            requestBody = redactSensitiveBody(options.data as Map);
          }
          AppLogger.apiRequest(
            options.method,
            uri,
            body: requestBody,
            extra: requestExtra,
          );

          return handler.next(options);
        },
        onResponse: (response, handler) {
          final uri = redactSensitiveUrl(response.requestOptions.uri.toString());
          final status = response.statusCode ?? 0;
          dynamic errorBody;
          if (status >= 400 && response.data != null) {
            errorBody = _summarizeBody(response.data, maxChars: 500);
          }
          AppLogger.apiResponse(
            response.requestOptions.method,
            uri,
            status,
            body: errorBody,
          );

          // Belt-and-suspenders: a per-request validateStatus override can
          // still deliver 4xx here. Default options now reject 4xx, so the
          // live path is onError.
          _handleClientErrorStatus(
            statusCode: response.statusCode,
            data: response.data,
            requestOptions: response.requestOptions,
          );

          return handler.next(response);
        },
        onError: (error, handler) async {
          final uri = redactSensitiveUrl(error.requestOptions.uri.toString());
          final code = error.response?.statusCode ?? 0;
          final summary = error.response?.data != null
              ? _summarizeBody(error.response!.data, maxChars: 500)
              : error.message;
          AppLogger.apiResponse(
            error.requestOptions.method,
            uri,
            code,
            body: summary,
          );
          AppLogger.error(
            'API failed: ${error.requestOptions.method} $uri',
            tag: 'API',
            error: error.message,
          );

          final statusCode = error.response?.statusCode;
          if (statusCode == 403 && _isBannedAccount(_asStringKeyMap(error.response?.data))) {
            _notifyBanned(error.requestOptions);
            return handler.next(error);
          }

          // Handle 401 Unauthorized - Token expired or invalid
          if (statusCode == 401) {
            final requestOptions = error.requestOptions;
            final path = requestOptions.path;
            final body = _asStringKeyMap(error.response?.data);

            // Background logout / explicit skip: never refresh or redirect.
            if (requestOptions.extra[kSkipUnauthorizedHandlerExtra] == true) {
              return handler.next(error);
            }

            // Login/register: wrong credentials — do NOT redirect to welcome
            final isLoginOrRegisterRequest = path.contains('/auth/login') ||
                path.contains('login-password') ||
                path.contains('/auth/register');
            if (isLoginOrRegisterRequest) {
              clearAuthToken();
              return handler.next(error);
            }

            // Plan/feature denial mislabeled as 401 — keep session
            final hadAuthToken = requestOptions.extra['had_auth_token'] == true;
            if (!ApiError.shouldForceLogout(
              statusCode: 401,
              body: body,
              requestPath: path,
              hadAuthTokenOnRequest: hadAuthToken,
            )) {
              return handler.next(error);
            }

            // A request sent by a previous session (optimistic logout, then
            // another account logged in) must never be refreshed or retried
            // with the new account's token, and must not end its session.
            final failedBearer = _bearerOf(requestOptions);
            if (failedBearer != null) {
              try {
                final current = await _tokenStorage.getAuthToken();
                if (current != null &&
                    current.isNotEmpty &&
                    current != failedBearer &&
                    current != _refreshedToken) {
                  return handler.next(error);
                }
              } catch (_) {
                // Storage unreadable: fall through to the normal 401 path.
              }
            }

            // Attempt token refresh
            try {
              final newToken = await _refreshTokenIfNeeded();
              if (newToken != null) {
                // Retry the original request with new token
                final opts = Options(
                  method: requestOptions.method,
                  headers: requestOptions.headers,
                );
                opts.headers!['Authorization'] = 'Bearer $newToken';
                
                final response = await _dio.request(
                  requestOptions.path,
                  options: opts,
                  data: requestOptions.data,
                  queryParameters: requestOptions.queryParameters,
                );
                return handler.resolve(response);
              } else {
                // Refresh failed, clear in-memory auth and notify (storage cleared in logout)
                clearAuthToken();
                _notifyUnauthorized(requestOptions);
                return handler.next(error);
              }
            } catch (e) {
              // Refresh failed, clear in-memory auth and notify (storage cleared in logout)
              clearAuthToken();
              _notifyUnauthorized(requestOptions);
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(SubscriptionMetaInterceptor());
  }

  /// Shared 401/403 handling for both onResponse (validateStatus override)
  /// and onError (normal 4xx). Does not attempt token refresh — that stays
  /// on the onError 401 path so a successful refresh can [handler.resolve].
  void _handleClientErrorStatus({
    required int? statusCode,
    required dynamic data,
    required RequestOptions requestOptions,
  }) {
    final body = _asStringKeyMap(data);

    if (statusCode == 403 && _isBannedAccount(body)) {
      _notifyBanned(requestOptions);
      return;
    }

    if (statusCode == 401) {
      if (requestOptions.extra[kSkipUnauthorizedHandlerExtra] == true) {
        return;
      }
      final hadAuthToken = requestOptions.extra['had_auth_token'] == true;
      if (ApiError.shouldForceLogout(
        statusCode: statusCode,
        body: body,
        requestPath: requestOptions.path,
        hadAuthTokenOnRequest: hadAuthToken,
      )) {
        clearAuthToken();
        _notifyUnauthorized(requestOptions);
      }
    }
  }

  static Map<String, dynamic>? _asStringKeyMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  /// Matches [EnsureUserNotBanned] and AuthController check-token payloads.
  static bool _isBannedAccount(Map<String, dynamic>? body) {
    if (body == null) return false;
    final nested = _asStringKeyMap(body['data']);
    final userState =
        nested?['user_state']?.toString() ?? body['user_state']?.toString();
    if (userState == 'banned') return true;
    if (nested?['banned'] == true) return true;
    if (body['banned'] == true) return true;
    return false;
  }

  /// Get Dio instance
  Dio get dio => _dio;

  /// Update auth token in headers
  Future<void> updateAuthToken(String? token) async {
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  /// Clear auth token from headers
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Notify app that user is unauthenticated (401). Schedules on UI thread.
  ///
  /// [request] is the call that failed. Logout is optimistic, so a request
  /// sent by the previous session can come back 401 (its token was revoked)
  /// after someone else has logged in. Only a 401 for the *current* session
  /// may end it.
  void _notifyUnauthorized(RequestOptions request) {
    final failedBearer = _bearerOf(request);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = await _tokenStorage.getAuthToken();
      if (!shouldEndSessionFor(
        failedRequestBearer: failedBearer,
        currentToken: token,
      )) {
        return;
      }
      UnauthorizedHandler.invoke();
    });
  }

  /// 403 banned: same stale-session rule as [_notifyUnauthorized].
  void _notifyBanned(RequestOptions request) {
    final failedBearer = _bearerOf(request);
    if (failedBearer == null) {
      clearAuthToken();
      BannedHandler.invoke();
      return;
    }
    unawaited(() async {
      String? token;
      try {
        token = await _tokenStorage.getAuthToken();
      } catch (_) {
        token = null;
      }
      if (token != null && token.isNotEmpty && token != failedBearer) {
        // A different account is signed in now; the ban belongs to the
        // previous session.
        return;
      }
      clearAuthToken();
      BannedHandler.invoke();
    }());
  }

  /// Whether a 401 on a request carrying [failedRequestBearer] should end
  /// the session whose stored token is [currentToken].
  ///
  /// - no stored token → already logged out, nothing to end;
  /// - the request carried a different token → it belonged to a previous
  ///   session (optimistic logout + re-login), so the current one is kept.
  @visibleForTesting
  static bool shouldEndSessionFor({
    required String? failedRequestBearer,
    required String? currentToken,
  }) {
    if (currentToken == null || currentToken.isEmpty) return false;
    if (failedRequestBearer != null &&
        failedRequestBearer.isNotEmpty &&
        failedRequestBearer != currentToken) {
      return false;
    }
    return true;
  }

  /// Refresh token if needed (handles concurrent requests)
  Future<String?> _refreshTokenIfNeeded() async {
    // If already refreshing, wait for it to complete
    if (_isRefreshing) {
      final completer = Completer<void>();
      _refreshQueue.add(completer);
      await completer.future;
      return _refreshedToken;
    }

    _isRefreshing = true;
    _refreshedToken = null;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ No refresh token available');
        }
        return null;
      }

      // Create a temporary Dio instance without interceptors to avoid recursion
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Attempt to refresh token
      // Note: This endpoint may not exist yet, but the structure is ready
      try {
        final response = await refreshDio.post(
          ApiEndpoints.authRefresh, // This will be added to ApiEndpoints
          data: {
            'refresh_token': refreshToken,
          },
        );

        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            final newToken = data['token'] as String? ?? 
                           data['access_token'] as String?;
            final newRefreshToken = data['refresh_token'] as String?;

            if (newToken != null && newToken.isNotEmpty) {
              // Save new tokens
              await _tokenStorage.saveAuthToken(newToken);
              if (newRefreshToken != null) {
                await _tokenStorage.saveRefreshToken(newRefreshToken);
              }

              _refreshedToken = newToken;
              
              if (kDebugMode) {
                debugPrint('✅ Token refreshed successfully');
              }

              // Notify waiting requests
              for (var completer in _refreshQueue) {
                completer.complete();
              }
              _refreshQueue.clear();

              return newToken;
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Token refresh failed: $e');
        }
        // If refresh endpoint doesn't exist or fails, return null
        // The app will handle this by requiring re-login
      }

      return null;
    } finally {
      _isRefreshing = false;
      // Notify waiting requests even if refresh failed
      for (var completer in _refreshQueue) {
        completer.complete();
      }
      _refreshQueue.clear();
    }
  }
}

