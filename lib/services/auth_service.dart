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

  Future<UserModel?> login(String email, String password, bool rememberMe) async {
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

        // Save remember me preference
        await _storage.saveRememberMe(rememberMe, email,password);

        return authResponse.data!.user;
      }

      throw Exception(authResponse.message);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      }
      throw Exception('Network error. Please try again.');
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

  Future<bool> checkAndRestoreSession() async {
    // Check if user has valid session
    final isLoggedIn = await _storage.isLoggedIn();
    if (isLoggedIn) {
      // Optionally validate token with server
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> getRememberMeData() async {
    final rememberMe = await _storage.getRememberMe();
    final savedEmail = await _storage.getSavedEmail();
    final savedPassword = await _storage.getSavedEmail();

    return {
      'rememberMe': rememberMe,
      'email': savedEmail ?? '',
      'password': savedPassword ?? '',
    };
  }

  // Send OTP to WhatsApp
  Future<Map<String, dynamic>> sendOtp(String phoneCode, String phoneNumber) async {
    try {
      final response = await _apiService.post(
        ApiConfig.requestOtpEndpoint,
        data: {
          'phoneCode': phoneCode,
          'phoneNumber': phoneNumber,
        },
      );

      if (response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'OTP sent successfully',
          'expiresAt': response.data['data']?['expiresAt'],
          'userExists': response.data['data']?['userExists'] ?? false,
        };
      }

      throw Exception(response.data['message'] ?? 'Failed to send OTP');
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response?.data['message'] ?? 'Failed to send OTP';
        throw Exception(message);
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  // Verify OTP and login
  Future<UserModel?> verifyOtp(String phoneCode, String phoneNumber, String otp) async {
    try {
      final response = await _apiService.post(
        ApiConfig.verifyOtpEndpoint,
        data: {
          'phoneCode': phoneCode,
          'phoneNumber': phoneNumber,
          'otp': otp,
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
        final message = e.response?.data['message'] ?? 'Invalid OTP';
        throw Exception(message);
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }
}