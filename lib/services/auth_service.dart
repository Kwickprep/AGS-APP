import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = GetIt.I<ApiService>();
  final StorageService _storage = GetIt.I<StorageService>();

  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConfig.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.data != null) {
        // Save tokens and user data
        await _storage.saveTokens(
          authResponse.data!.accessToken,
          authResponse.data!.refreshToken,
        );
        await _storage.saveUser(authResponse.data!.user);

        return authResponse.data!.user;
      }

      throw Exception(authResponse.message);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      }
      throw Exception(e.error);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
  }

  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  Future<UserModel?> getCurrentUser() async {
    return await _storage.getUser();
  }
}
