import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/models/user_model.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<UserModel?> updateProfile({
    required String email,
    int? height,
    double? weight,
    XFile? photo,
  }) async {
    try {
      final formData = FormData.fromMap({
        'email': email,
        if (height != null) 'height': height.toString(),
        if (weight != null) 'weight': weight.toString(),
        if (photo != null)
          'photo': MultipartFile.fromBytes(
            await photo.readAsBytes(),
            filename: photo.name,
          ),
      });

      final response = await _apiClient.dio.put(
        '/api/users/profile',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }
}
