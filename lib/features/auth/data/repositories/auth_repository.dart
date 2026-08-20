import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:viva_livre_app/core/api/api_client.dart';
import 'package:viva_livre_app/core/models/user_model.dart';
import 'package:viva_livre_app/core/database/local_database.dart';

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

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String cpf,
    required String dateOfBirth,
    required String gender,
    double? weight,
    double? height,
    required String clinicalCondition,
    required List<String> comorbidities,
  }) async {
    try {
      final response = await _apiClient.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'cpf': cpf,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'weight': weight,
        'height': height,
        'clinical_condition': clinicalCondition,
        'comorbidities': comorbidities,
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
    await LocalDatabase.instance.clearAll();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }

  Future<UserModel?> checkAuth() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      try {
        final response = await _apiClient.dio.get('/api/users/me');
        if (response.statusCode == 200) {
          return UserModel.fromJson(response.data);
        }
      } catch (e) {
        // Se houver erro (token inválido/expirado), faz o logout e limpa o token
        await logout();
      }
    }
    return null;
  }

  Future<UserModel?> loginWithGoogle() async {
    try {
      const clientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '437244400535-vvkllcs0vnv3ph8hag4piapkn9i7un65.apps.googleusercontent.com');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: clientId.isNotEmpty ? clientId : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Não foi possível obter o ID Token do Google.');
      }

      final response = await _apiClient.dio.post('/api/auth/google', data: {
        'id_token': idToken,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
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

  Future<void> forgotPassword(String email) async {
    try {
      final response = await _apiClient.dio.post('/api/auth/forgot-password', data: {
        'email': email,
      });
      if (response.statusCode != 200) {
        throw Exception('Erro ao solicitar recuperação de senha.');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await _apiClient.dio.post('/api/auth/reset-password', data: {
        'token': token,
        'new_password': newPassword,
      });
      if (response.statusCode != 200) {
        throw Exception('Erro ao redefinir a senha.');
      }
    } catch (e) {
      rethrow;
    }
  }

}
