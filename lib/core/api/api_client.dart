import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    // Determine Base URL based on Platform
    // 10.0.2.2 is the address to access localhost from Android Emulator
    String baseUrl = 'http://localhost:8080';
    
    if (!kIsWeb && Platform.isAndroid) {
      // Usando o IP local da máquina para permitir acesso por dispositivos físicos na mesma rede
      baseUrl = 'http://192.168.18.5:8080';
    }

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add Security Interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          // You could trigger a logout event here via a stream if needed
          debugPrint('Unauthorized access - 401');
        }
        return handler.next(e);
      },
    ));

    // Log interceptor for debug mode
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }
}
