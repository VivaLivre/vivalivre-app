import 'dart:async';
import 'package:dio/dio.dart';

Future<T> retryOperation<T>({
  required Future<T> Function() operation,
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  Object? lastError;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await operation();
    } on DioException catch (e) {
      lastError = e;
      // Retry on network errors, timeouts, and 5xx server errors
      final isRetryable = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          (e.response?.statusCode != null && e.response!.statusCode! >= 500);

      if (!isRetryable || attempt == maxAttempts) {
        rethrow;
      }
    } on TimeoutException catch (e) {
      lastError = e;
      if (attempt == maxAttempts) {
        rethrow;
      }
    } catch (e) {
      lastError = e;
      if (attempt == maxAttempts) {
        rethrow;
      }
    }

    final delay = initialDelay * attempt;
    await Future.delayed(delay);
  }

  throw lastError ?? Exception('Operação falhou após múltiplas tentativas.');
}
