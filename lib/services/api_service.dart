import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  late Dio _dio;
  final StorageService _storage = GetIt.I<StorageService>();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectionTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final token = await _storage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Handle token refresh here (stub for now)
            final refreshToken = await _storage.getRefreshToken();
            if (refreshToken != null) {
              // TODO: Implement refresh token logic
              // final newToken = await _refreshToken(refreshToken);
              // if (newToken != null) {
              //   error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              //   return handler.resolve(await _dio.fetch(error.requestOptions));
              // }
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

  // Stub for refresh token
  Future<String?> refreshToken(String refreshToken) async {
    // TODO: Implement when refresh endpoint is provided
    return null;
  }
}
