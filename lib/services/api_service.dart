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
          'x-platform': 'webapp',
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

          // Log request details
          _logRequest(options);

          handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response details
          _logResponse(response);
          handler.next(response);
        },
        onError: (error, handler) async {
          // Log error details
          _logError(error);

          if (error.response?.statusCode == 401) {
            // Token expired or invalid - logout user
            if (kDebugMode) {
              print('\n🚨 Token expired or invalid - Logging out user...');
            }

            // Get auth service and logout
            try {
              final authService = GetIt.I<AuthService>();
              await authService.logout();

              if (kDebugMode) {
                print('✅ User logged out successfully');
              }
            } catch (e) {
              if (kDebugMode) {
                print('❌ Error during logout: $e');
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // Log API Request
  void _logRequest(RequestOptions options) {
    if (kDebugMode) {
      print('\n');
      print('╔════════════════════════════════════════════════════════════════════════════╗');
      print('║                           API REQUEST                                      ║');
      print('╚════════════════════════════════════════════════════════════════════════════╝');
      print('📍 URL: ${options.baseUrl}${options.path}');
      print('🔧 METHOD: ${options.method}');
      print('⏰ TIMESTAMP: ${DateTime.now().toIso8601String()}');

      if (options.headers.isNotEmpty) {
        print('\n📋 HEADERS:');
        print('┌────────────────────────────────────────────────────────────────────────────┐');
        options.headers.forEach((key, value) {
          // Mask authorization token for security
          if (key.toLowerCase() == 'authorization' && value != null) {
            final tokenValue = value.toString();
            if (tokenValue.length > 20) {
              if (kDebugMode) {
                print('│ $key: ${tokenValue.substring(0, 20)}...${tokenValue.substring(tokenValue.length - 10)}');
              }
            } else {
              print('│ $key: $value');
            }
          } else {
            print('│ $key: $value');
          }
        });
        print('└────────────────────────────────────────────────────────────────────────────┘');
      }

      if (options.queryParameters.isNotEmpty) {
        print('\n🔍 QUERY PARAMETERS:');
        print('┌────────────────────────────────────────────────────────────────────────────┐');
        options.queryParameters.forEach((key, value) {
          print('│ $key: $value');
        });
        print('└────────────────────────────────────────────────────────────────────────────┘');
      }

      if (options.data != null) {
        print('\n📦 REQUEST BODY:');
        print('┌────────────────────────────────────────────────────────────────────────────┐');
        try {
          final data = options.data;
          if (data is Map) {
            data.forEach((key, value) {
              // Mask sensitive data
              if (key.toLowerCase().contains('password') ||
                  key.toLowerCase().contains('otp') ||
                  key.toLowerCase().contains('token')) {
                print('│ $key: ********');
              } else {
                print('│ $key: $value');
              }
            });
          } else {
            print('│ ${options.data}');
          }
        } catch (e) {
          print('│ ${options.data}');
        }
        print('└────────────────────────────────────────────────────────────────────────────┘');
      }
      print('════════════════════════════════════════════════════════════════════════════\n');
    }
  }

  // Log API Response
  void _logResponse(Response response) {
    if (kDebugMode) {
      print('\n');
      print('╔════════════════════════════════════════════════════════════════════════════╗');
      print('║                          API RESPONSE                                      ║');
      print('╚════════════════════════════════════════════════════════════════════════════╝');
      print('📍 URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}');
      print('🔧 METHOD: ${response.requestOptions.method}');
      print('✅ STATUS CODE: ${response.statusCode}');
      print('📊 STATUS MESSAGE: ${response.statusMessage}');
      print('⏰ TIMESTAMP: ${DateTime.now().toIso8601String()}');

      if (response.headers.map.isNotEmpty) {
        print('\n📋 RESPONSE HEADERS:');
        print('┌────────────────────────────────────────────────────────────────────────────┐');
        response.headers.map.forEach((key, value) {
          print('│ $key: ${value.join(', ')}');
        });
        print('└────────────────────────────────────────────────────────────────────────────┘');
      }

      if (response.data != null) {
        print('\n📦 RESPONSE BODY:');
        print('┌────────────────────────────────────────────────────────────────────────────┐');
        try {
          final prettyJson = _formatJson(response.data);
          prettyJson.split('\n').forEach((line) {
            print('│ $line');
          });
        } catch (e) {
          print('│ ${response.data}');
        }
        print('└────────────────────────────────────────────────────────────────────────────┘');
      }
      print('════════════════════════════════════════════════════════════════════════════\n');
    }
  }

  // Log API Error
  void _logError(DioException error) {
    if (kDebugMode) {
      print('\n');
      print('╔════════════════════════════════════════════════════════════════════════════╗');
      print('║                           API ERROR                                        ║');
      print('╚════════════════════════════════════════════════════════════════════════════╝');
      print('📍 URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}');
      print('🔧 METHOD: ${error.requestOptions.method}');
      print('❌ ERROR TYPE: ${error.type}');
      print('💬 ERROR MESSAGE: ${error.message}');
      print('⏰ TIMESTAMP: ${DateTime.now().toIso8601String()}');

      if (error.response != null) {
        print('\n🚫 ERROR RESPONSE:');
        print('┌────────────────────────────────────────────────────────────────────────────┐');
        print('│ STATUS CODE: ${error.response?.statusCode}');
        print('│ STATUS MESSAGE: ${error.response?.statusMessage}');

        if (error.response?.data != null) {
          print('│');
          print('│ RESPONSE DATA:');
          try {
            final prettyJson = _formatJson(error.response?.data);
            prettyJson.split('\n').forEach((line) {
              print('│   $line');
            });
          } catch (e) {
            print('│   ${error.response?.data}');
          }
        }
        print('└────────────────────────────────────────────────────────────────────────────┘');
      }

      print('\n📚 STACK TRACE:');
      print('┌────────────────────────────────────────────────────────────────────────────┐');
      final stackLines = error.stackTrace.toString().split('\n').take(5);
      for (var line in stackLines) {
        print('│ $line');
      }
      print('└────────────────────────────────────────────────────────────────────────────┘');
          print('════════════════════════════════════════════════════════════════════════════\n');
    }
  }

  // Format JSON for pretty printing
  String _formatJson(dynamic json) {
    try {
      if (json is Map || json is List) {
        return _prettyPrintJson(json, 0);
      }
      return json.toString();
    } catch (e) {
      return json.toString();
    }
  }

  String _prettyPrintJson(dynamic json, int indent) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;

    if (json is Map) {
      buffer.write('{');
      final entries = json.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        buffer.write('\n$indentStr  "${entry.key}": ');

        if (entry.value is Map || entry.value is List) {
          buffer.write(_prettyPrintJson(entry.value, indent + 1));
        } else if (entry.value is String) {
          buffer.write('"${entry.value}"');
        } else {
          buffer.write('${entry.value}');
        }

        if (i < entries.length - 1) buffer.write(',');
      }
      buffer.write('\n$indentStr}');
    } else if (json is List) {
      buffer.write('[');
      for (var i = 0; i < json.length; i++) {
        buffer.write('\n$indentStr  ');
        if (json[i] is Map || json[i] is List) {
          buffer.write(_prettyPrintJson(json[i], indent + 1));
        } else if (json[i] is String) {
          buffer.write('"${json[i]}"');
        } else {
          buffer.write('${json[i]}');
        }
        if (i < json.length - 1) buffer.write(',');
      }
      buffer.write('\n$indentStr]');
    } else {
      buffer.write(json.toString());
    }

    return buffer.toString();
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
