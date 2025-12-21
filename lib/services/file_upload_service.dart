import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'api_service.dart';

class FileUploadService {
  final ApiService _apiService = GetIt.I<ApiService>();
  late final Dio _dio;

  FileUploadService() {
    _dio = _apiService.dio;
  }

  /// Upload single file to /api/files endpoint
  /// Returns file information including documentId
  Future<String> uploadFile(File file, {bool isPublic = true}) async {
    try {
      final fileName = path.basename(file.path);
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final bytes = await file.readAsBytes();

      // Create FormData for file upload
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
        'public': isPublic.toString(),
      });

      // Call files API endpoint
      final response = await _dio.post(
        '/api/files',
        data: formData,
      );

      // Extract document ID from response
      if (response.data != null &&
          response.data['data'] != null &&
          response.data['data']['record'] != null &&
          response.data['data']['record']['id'] != null) {
        return response.data['data']['record']['id'] as String;
      } else {
        throw Exception('Failed to get document ID from response');
      }
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  /// Upload multiple files and return list of document IDs
  Future<List<String>> uploadMultipleFiles(List<File> files) async {
    final List<String> documentIds = [];

    for (final file in files) {
      final documentId = await uploadFile(file);
      documentIds.add(documentId);
    }

    return documentIds;
  }

  /// Get file URL from document ID (for preview/display)
  String getFileUrl(String documentId) {
    // Construct file URL - adjust based on your API response structure
    return '${_apiService.dio.options.baseUrl}/api/files/$documentId';
  }
}
