import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final userData = response.data['user'];
        
        // Persist JWT Token
        await _storage.write(key: 'jwt_token', value: token);
        
        return UserModel.fromJson(userData);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<UserModel?> register(String name, String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201) {
        final token = response.data['token'];
        final userData = response.data['user'];
        
        // Persist JWT Token
        await _storage.write(key: 'jwt_token', value: token);
        
        return UserModel.fromJson(userData);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }
}
