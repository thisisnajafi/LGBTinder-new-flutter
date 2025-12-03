import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/dio_client.dart';
import '../models/api_response.dart';
import '../models/api_error.dart';
import 'connectivity_service.dart';
import 'cache_service.dart';
import 'offline_queue_service.dart';
import 'retry_service.dart';
import 'dart:io';

/// Base API service with common HTTP methods
class ApiService {
  final DioClient _dioClient;
  final ConnectivityService _connectivityService;
  final CacheService _cacheService;
  final OfflineQueueService _queueService;
  final Uuid _uuid = const Uuid();

  ApiService(
    this._dioClient,
    this._connectivityService,
    this._cacheService,
    this._queueService,
  );

  /// GET request with offline support
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    // Generate cache key
    final cacheKey = _generateCacheKey('GET', endpoint, queryParameters);

    // Try to get from cache if online and cache is enabled
    if (useCache && !forceRefresh) {
      final cached = await _cacheService.getCached<T>(
        cacheKey,
        (json) => fromJson != null ? fromJson(json) : json as T,
      );
      if (cached != null) {
        return ApiResponse.fromData(cached, fromJson);
      }
    }

    // Check connectivity
    if (!_connectivityService.isOnline) {
      // Try to get from cache as fallback
      if (useCache) {
        final cached = await _cacheService.getCached<T>(
          cacheKey,
          (json) => fromJson != null ? fromJson(json) : json as T,
        );
        if (cached != null) {
          return ApiResponse.fromData(cached, fromJson);
        }
      }
      throw ApiError(
        message: 'No internet connection. Please check your network and try again.',
        code: 0,
      );
    }

    try {
      // Use retry service for network requests
      final apiResponse = await RetryService.executeWithRetry<ApiResponse<T>>(
        operation: () async {
          final response = await _dioClient.dio.get(
            endpoint,
            queryParameters: queryParameters,
            options: options,
          );
          return _handleResponse<T>(response, fromJson);
        },
        config: RetryConfig(
          maxRetries: 3,
          initialDelay: const Duration(seconds: 1),
          backoffMultiplier: 2.0,
          maxDelay: const Duration(seconds: 30),
          shouldRetry: (error) {
            // Don't retry if it's a client error (4xx except 429)
            // Validation errors (422) should never be retried
            if (error is ApiError) {
              if (error.code != null) {
                // All 4xx errors except 429 (rate limit) should not be retried
                if (error.code! >= 400 && error.code! < 500 && error.code != 429) {
                  return false;
                }
              }
              // Also check if it has validation errors - these should never be retried
              if (error.errors != null && error.errors!.isNotEmpty) {
                return false;
              }
            }
            return RetryService.isRetryableError(error);
          },
        ),
      );

      // Cache successful GET responses
      if (useCache && apiResponse.isSuccess && apiResponse.data != null) {
        if (apiResponse.data is Map<String, dynamic>) {
          await _cacheService.cacheData(cacheKey, apiResponse.data as Map<String, dynamic>);
        }
      }

      return apiResponse;
    } on DioException catch (e) {
      // If offline error, try cache
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.unknown) {
        if (useCache) {
          final cached = await _cacheService.getCached<T>(
            cacheKey,
            (json) => fromJson != null ? fromJson(json) : json as T,
          );
          if (cached != null) {
            return ApiResponse.fromData(cached, fromJson);
          }
        }
      }
      throw ApiError.fromDioException(e);
    } catch (e) {
      // If it's already an ApiError, rethrow it
      if (e is ApiError) {
        rethrow;
      }
      throw ApiError(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// POST request with offline queue support
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    T Function(dynamic)? fromJson,
    Options? options,
    bool queueIfOffline = true,
  }) async {
    // Check connectivity
    if (!_connectivityService.isOnline) {
      if (queueIfOffline) {
        // Queue the request for later
        await _queueService.queueRequest(
          QueuedRequest(
            id: _uuid.v4(),
            method: 'POST',
            endpoint: endpoint,
            data: data,
            createdAt: DateTime.now(),
          ),
        );
        throw ApiError(
          message: 'No internet connection. Request queued and will be sent when online.',
          code: 0,
        );
      } else {
        throw ApiError(
          message: 'No internet connection. Please check your network and try again.',
          code: 0,
        );
      }
    }

    try {
      // Use retry service for network requests
      return await RetryService.executeWithRetry<ApiResponse<T>>(
        operation: () async {
          final response = await _dioClient.dio.post(
            endpoint,
            data: data,
            options: options,
          );
          return _handleResponse<T>(response, fromJson);
        },
        config: RetryConfig(
          maxRetries: 3,
          initialDelay: const Duration(seconds: 1),
          backoffMultiplier: 2.0,
          maxDelay: const Duration(seconds: 30),
          shouldRetry: (error) {
            // Don't retry if it's a client error (4xx except 429)
            // Validation errors (422) should never be retried
            if (error is ApiError) {
              if (error.code != null) {
                // All 4xx errors except 429 (rate limit) should not be retried
                if (error.code! >= 400 && error.code! < 500 && error.code != 429) {
                  return false;
                }
              }
              // Also check if it has validation errors - these should never be retried
              if (error.errors != null && error.errors!.isNotEmpty) {
                return false;
              }
            }
            return RetryService.isRetryableError(error);
          },
        ),
      );
    } on DioException catch (e) {
      // If offline error and queueing is enabled, queue the request
      if (queueIfOffline && 
          (e.type == DioExceptionType.connectionTimeout || 
           e.type == DioExceptionType.unknown)) {
        await _queueService.queueRequest(
          QueuedRequest(
            id: _uuid.v4(),
            method: 'POST',
            endpoint: endpoint,
            data: data,
            createdAt: DateTime.now(),
          ),
        );
      }
      throw ApiError.fromDioException(e);
    } catch (e) {
      // If it's already an ApiError, rethrow it
      if (e is ApiError) {
        rethrow;
      }
      throw ApiError(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// PUT request with offline queue support
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    T Function(dynamic)? fromJson,
    Options? options,
    bool queueIfOffline = true,
  }) async {
    // Check connectivity
    if (!_connectivityService.isOnline) {
      if (queueIfOffline) {
        await _queueService.queueRequest(
          QueuedRequest(
            id: _uuid.v4(),
            method: 'PUT',
            endpoint: endpoint,
            data: data,
            createdAt: DateTime.now(),
          ),
        );
        throw ApiError(
          message: 'No internet connection. Request queued and will be sent when online.',
          code: 0,
        );
      } else {
        throw ApiError(
          message: 'No internet connection. Please check your network and try again.',
          code: 0,
        );
      }
    }

    try {
      // Use retry service for network requests
      return await RetryService.executeWithRetry<ApiResponse<T>>(
        operation: () async {
          final response = await _dioClient.dio.put(
            endpoint,
            data: data,
            options: options,
          );
          return _handleResponse<T>(response, fromJson);
        },
        config: RetryConfig(
          maxRetries: 3,
          initialDelay: const Duration(seconds: 1),
          backoffMultiplier: 2.0,
          maxDelay: const Duration(seconds: 30),
          shouldRetry: (error) {
            // Don't retry if it's a client error (4xx except 429)
            // Validation errors (422) should never be retried
            if (error is ApiError) {
              if (error.code != null) {
                // All 4xx errors except 429 (rate limit) should not be retried
                if (error.code! >= 400 && error.code! < 500 && error.code != 429) {
                  return false;
                }
              }
              // Also check if it has validation errors - these should never be retried
              if (error.errors != null && error.errors!.isNotEmpty) {
                return false;
              }
            }
            return RetryService.isRetryableError(error);
          },
        ),
      );
    } on DioException catch (e) {
      if (queueIfOffline && 
          (e.type == DioExceptionType.connectionTimeout || 
           e.type == DioExceptionType.unknown)) {
        await _queueService.queueRequest(
          QueuedRequest(
            id: _uuid.v4(),
            method: 'PUT',
            endpoint: endpoint,
            data: data,
            createdAt: DateTime.now(),
          ),
        );
      }
      throw ApiError.fromDioException(e);
    } catch (e) {
      // If it's already an ApiError, rethrow it
      if (e is ApiError) {
        rethrow;
      }
      throw ApiError(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// DELETE request with offline queue support
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    T Function(dynamic)? fromJson,
    Options? options,
    bool queueIfOffline = false, // DELETE usually shouldn't be queued
  }) async {
    // Check connectivity
    if (!_connectivityService.isOnline) {
      if (queueIfOffline) {
        await _queueService.queueRequest(
          QueuedRequest(
            id: _uuid.v4(),
            method: 'DELETE',
            endpoint: endpoint,
            data: data,
            createdAt: DateTime.now(),
          ),
        );
        throw ApiError(
          message: 'No internet connection. Request queued and will be sent when online.',
          code: 0,
        );
      } else {
        throw ApiError(
          message: 'No internet connection. Please check your network and try again.',
          code: 0,
        );
      }
    }

    try {
      // Use retry service for network requests
      return await RetryService.executeWithRetry<ApiResponse<T>>(
        operation: () async {
          final response = await _dioClient.dio.delete(
            endpoint,
            data: data,
            options: options,
          );
          return _handleResponse<T>(response, fromJson);
        },
        config: RetryConfig(
          maxRetries: 3,
          initialDelay: const Duration(seconds: 1),
          backoffMultiplier: 2.0,
          maxDelay: const Duration(seconds: 30),
          shouldRetry: (error) {
            // Don't retry if it's a client error (4xx except 429)
            // Validation errors (422) should never be retried
            if (error is ApiError) {
              if (error.code != null) {
                // All 4xx errors except 429 (rate limit) should not be retried
                if (error.code! >= 400 && error.code! < 500 && error.code != 429) {
                  return false;
                }
              }
              // Also check if it has validation errors - these should never be retried
              if (error.errors != null && error.errors!.isNotEmpty) {
                return false;
              }
            }
            return RetryService.isRetryableError(error);
          },
        ),
      );
    } on DioException catch (e) {
      if (queueIfOffline && 
          (e.type == DioExceptionType.connectionTimeout || 
           e.type == DioExceptionType.unknown)) {
        await _queueService.queueRequest(
          QueuedRequest(
            id: _uuid.v4(),
            method: 'DELETE',
            endpoint: endpoint,
            data: data,
            createdAt: DateTime.now(),
          ),
        );
      }
      throw ApiError.fromDioException(e);
    } catch (e) {
      // If it's already an ApiError, rethrow it
      if (e is ApiError) {
        rethrow;
      }
      throw ApiError(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Upload file (multipart/form-data)
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    File file, {
    String fieldName = 'image',
    Map<String, dynamic>? fields,
    T Function(dynamic)? fromJson,
    ProgressCallback? onSendProgress,
    Options? options,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        if (fields != null) ...fields,
      });

      final response = await _dioClient.dio.post(
        endpoint,
        data: formData,
        options: options ?? Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: onSendProgress,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Upload multiple files
  Future<ApiResponse<T>> uploadFiles<T>(
    String endpoint,
    List<File> files, {
    String fieldName = 'images',
    Map<String, dynamic>? fields,
    T Function(dynamic)? fromJson,
    ProgressCallback? onSendProgress,
    Options? options,
  }) async {
    try {
      // Properly await all MultipartFile creations
      final multipartFiles = await Future.wait(
        files.asMap().entries.map((entry) async {
          final index = entry.key;
          final file = entry.value;
          final fileName = file.path.split('/').last;
          final multipartFile = await MultipartFile.fromFile(file.path, filename: fileName);
          // Use indexed format for Laravel array recognition: images[0], images[1], etc.
          return MapEntry('$fieldName[$index]', multipartFile);
        }),
      );
      
      final formData = FormData.fromMap({
        ...Map.fromEntries(multipartFiles),
        if (fields != null) ...fields,
      });

      final response = await _dioClient.dio.post(
        endpoint,
        data: formData,
        options: options ?? Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: onSendProgress,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    } catch (e) {
      throw ApiError(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Generate cache key from request parameters
  String _generateCacheKey(
    String method,
    String endpoint,
    Map<String, dynamic>? queryParameters,
  ) {
    final buffer = StringBuffer();
    buffer.write(method);
    buffer.write('_');
    buffer.write(endpoint.replaceAll('/', '_'));
    
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final sortedKeys = queryParameters.keys.toList()..sort();
      for (final key in sortedKeys) {
        buffer.write('_');
        buffer.write(key);
        buffer.write('_');
        buffer.write(queryParameters[key].toString());
      }
    }
    
    return buffer.toString();
  }

  /// Handle API response
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return ApiResponse.fromJson(data, fromJson);
      } else {
        // If response is not a map, assume it's the data directly
        return ApiResponse.fromData(data, fromJson);
      }
    } else {
      // Handle error response
      if (response.data is Map<String, dynamic>) {
        final error = ApiError.fromResponse(
          response.data as Map<String, dynamic>,
          statusCode: response.statusCode,
          responseData: response.data as Map<String, dynamic>, // Preserve full response data
        );
        throw error;
      } else {
        throw ApiError(
          code: response.statusCode,
          message: 'An error occurred',
        );
      }
    }
  }
}
