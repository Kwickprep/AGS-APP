import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../config/api_config.dart';
import 'storage_service.dart';
import 'auth_service.dart';

class ApiService {
  late Dio _dio;
  final StorageService _storage = GetIt.I<StorageService>();

  // Expose Dio instance for file uploads
  Dio get dio => _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectionTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'x-platform': 'mobile',
        },
      ),
    );

    // Add logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final token = await _storage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Minimal logging - only URL and method
          if (kDebugMode) {
            print('🌐 ${options.method} ${options.path}');
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          // Minimal logging - only status code
          if (kDebugMode) {
            print('✅ ${response.statusCode} ${response.requestOptions.path}');
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          // Log only essential error info
          if (kDebugMode) {
            print(
              '❌ ${error.response?.statusCode ?? 'ERROR'} ${error.requestOptions.path}',
            );
            if (error.response?.data != null) {
              print('   ${error.response?.data}');
            }
          }

          if (error.response?.statusCode == 401) {
            // Token expired or invalid - logout user
            if (kDebugMode) {
              print('🚨 Token expired - Logging out...');
            }

            // Get auth service and logout
            try {
              final authService = GetIt.I<AuthService>();
              await authService.logout();
            } catch (e) {
              if (kDebugMode) {
                print('❌ Logout error: $e');
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    try {
      return await _dio.get(path, queryParameters: params);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // Stub for refresh token
  Future<String?> refreshToken(String refreshToken) async {
    // TODO: Implement when refresh endpoint is provided
    return null;
  }
}
