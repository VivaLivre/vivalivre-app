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
    DateTime? birthDate,
    String? gender,
    String? cpf,
    String? clinicalCondition,
    List<String>? comorbidities,
    XFile? photo,
  }) async {
    try {
      final formData = FormData.fromMap({
        'email': email,
        if (height != null) 'height': height.toString(),
        if (weight != null) 'weight': weight.toString(),
        if (birthDate != null) 'birth_date': '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
        if (gender != null) 'gender': gender,
        if (cpf != null) 'cpf': cpf,
        if (clinicalCondition != null) 'clinical_condition': clinicalCondition,
        if (comorbidities != null)
          for (int i = 0; i < comorbidities.length; i++)
            'comorbidities': comorbidities[i],
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
