import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../shared/services/token_storage_service.dart';
import '../../core/constants/api_endpoints.dart';

/// Dio HTTP client with interceptors for authentication and error handling
class DioClient {
  static const String baseUrl = 'http://lg.abolfazlnajafi.com/api';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  late final Dio _dio;
  final TokenStorageService _tokenStorage;
  
  // Token refresh state
  bool _isRefreshing = false;
  final List<Completer<void>> _refreshQueue = [];
  String? _refreshedToken;

  DioClient(this._tokenStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          // Accept status codes 200-299 and 400-499 as valid
          return status != null && (status < 500 || status >= 600);
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Request Interceptor - Add auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final token = await _tokenStorage.getAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Log request in debug mode
          if (kDebugMode) {
            debugPrint('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
            debugPrint('Headers: ${options.headers}');
            if (options.data != null) {
              debugPrint('Data: ${options.data}');
            }
            if (options.queryParameters.isNotEmpty) {
              debugPrint('QueryParams: ${options.queryParameters}');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response in debug mode
          if (kDebugMode) {
            debugPrint('✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
            debugPrint('Data: ${response.data}');
          }

          return handler.next(response);
        },
        onError: (error, handler) async {
          // Log error in debug mode
          if (kDebugMode) {
            debugPrint('❌ ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
            debugPrint('Message: ${error.message}');
            if (error.response != null) {
              debugPrint('Response Data: ${error.response?.data}');
            }
          }

          // Handle 401 Unauthorized - Token expired or invalid
          if (error.response?.statusCode == 401) {
            final requestOptions = error.requestOptions;
            
            // Skip refresh for auth endpoints
            if (requestOptions.path.contains('/auth/') || 
                requestOptions.path.contains('/login') ||
                requestOptions.path.contains('/register')) {
              _tokenStorage.clearAllTokens();
              return handler.next(error);
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
                // Refresh failed, clear tokens
                _tokenStorage.clearAllTokens();
                return handler.next(error);
              }
            } catch (e) {
              // Refresh failed, clear tokens
              _tokenStorage.clearAllTokens();
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );

    // Logging Interceptor (only in debug mode)
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ));
    }
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
          baseUrl: baseUrl,
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

