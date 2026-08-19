import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:viva_livre_app/app.dart';

class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    // Determine Base URL
    // Aceita a URL via variável de ambiente ou usa o localhost/10.0.2.2 consoante a plataforma
    String envUrl = const String.fromEnvironment('API_URL');
    String baseUrl = envUrl.isNotEmpty
        ? envUrl
        : (kIsWeb ? 'http://localhost:8080' : (defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2:8080' : 'http://localhost:8080'));

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add Security Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            debugPrint('Unauthorized access - 401');
            _storage.delete(key: 'jwt_token');
            globalNavigatorKey.currentState?.pushReplacementNamed('/login');
          }
          return handler.next(e);
        },
      ),
    );

    // Log interceptor for debug mode
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }
}
