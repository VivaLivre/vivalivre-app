import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

Future<T> retryOperation<T>({
  required Future<T> Function() operation,
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  Object? lastError;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      lastError = e;
      final isRetryable = e.code == 'unavailable' ||
          e.code == 'deadline-exceeded' ||
          e.code == 'aborted' ||
          e.code == 'resource-exhausted' ||
          e.code == 'internal' ||
          e.code == 'network-request-failed';

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
