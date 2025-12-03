import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Configuration for retry behavior
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(dynamic error)? shouldRetry;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.shouldRetry,
  });

  /// Default retry config for network errors
  static const RetryConfig network = RetryConfig(
    maxRetries: 3,
    initialDelay: Duration(seconds: 1),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 30),
  );

  /// Retry config for server errors (5xx)
  static const RetryConfig serverError = RetryConfig(
    maxRetries: 2,
    initialDelay: Duration(seconds: 2),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 20),
  );

  /// Retry config for rate limiting (429)
  static const RetryConfig rateLimit = RetryConfig(
    maxRetries: 5,
    initialDelay: Duration(seconds: 5),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 60),
  );
}

/// Service for handling retries with exponential backoff
class RetryService {
  /// Execute a function with retry logic
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    RetryConfig config = const RetryConfig(),
    void Function(int attempt, Duration delay)? onRetry,
  }) async {
    int attempt = 0;
    Duration delay = config.initialDelay;

    while (attempt <= config.maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;

        // Check if we should retry this error
        if (config.shouldRetry != null && !config.shouldRetry!(error)) {
          rethrow;
        }

        // Don't retry if we've exceeded max retries
        if (attempt > config.maxRetries) {
          if (kDebugMode) {
            debugPrint('❌ Max retries ($config.maxRetries) exceeded for operation');
          }
          rethrow;
        }

        // Calculate delay with exponential backoff and jitter
        final jitter = Duration(
          milliseconds: Random().nextInt(500),
        );
        final totalDelay = Duration(
          milliseconds: (delay.inMilliseconds * config.backoffMultiplier).round(),
        );
        delay = Duration(
          milliseconds: (totalDelay.inMilliseconds + jitter.inMilliseconds)
              .clamp(0, config.maxDelay.inMilliseconds),
        );

        if (kDebugMode) {
          debugPrint('🔄 Retrying operation (attempt $attempt/${config.maxRetries}) after ${delay.inSeconds}s');
        }

        // Notify about retry
        onRetry?.call(attempt, delay);

        // Wait before retrying
        await Future.delayed(delay);
      }
    }

    // This should never be reached, but Dart requires it
    throw Exception('Retry logic error');
  }

  /// Check if an error is retryable
  static bool isRetryableError(dynamic error) {
    // Network errors are retryable
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('connection') ||
        error.toString().contains('network')) {
      return true;
    }

    // Server errors (5xx) are retryable
    if (error.toString().contains('500') ||
        error.toString().contains('502') ||
        error.toString().contains('503') ||
        error.toString().contains('504')) {
      return true;
    }

    // Rate limiting (429) is retryable
    if (error.toString().contains('429')) {
      return true;
    }

    // Client errors (4xx except 429) are not retryable
    if (error.toString().contains('400') ||
        error.toString().contains('401') ||
        error.toString().contains('403') ||
        error.toString().contains('404') ||
        error.toString().contains('422')) {
      return false;
    }

    // Default: retry unknown errors
    return true;
  }

  /// Get appropriate retry config based on error type
  static RetryConfig getRetryConfig(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Rate limiting
    if (errorString.contains('429') || errorString.contains('rate limit')) {
      return RetryConfig.rateLimit;
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504') ||
        errorString.contains('server error')) {
      return RetryConfig.serverError;
    }

    // Network errors (default)
    return RetryConfig.network;
  }
}

