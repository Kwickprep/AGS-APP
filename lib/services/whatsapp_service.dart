import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '../models/whatsapp_contact_model.dart';
import 'api_service.dart';

class WhatsAppService {
  final ApiService _apiService = GetIt.I<ApiService>();

  Future<WhatsAppContactsResponse> getContacts() async {
    try {
      final response = await _apiService.get('/api/whatsapp/contacts');
      return WhatsAppContactsResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load contacts: ${e.toString()}');
    }
  }

  Future<List<WhatsAppMessage>> getMessages(
    String recipientId, {
    int limit = 50,
    int page = 1,
  }) async {
    try {
      final encodedParams = Uri.encodeComponent('{"limit":$limit,"page":$page}');

      final response = await _apiService.get(
        '/api/whatsapp/messages/$recipientId?params=$encodedParams',
      );

      final data = response.data['data'] ?? {};
      final records = data['records'] as List<dynamic>? ?? [];

      return records.map((e) => WhatsAppMessage.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load messages: ${e.toString()}');
    }
  }

  Future<WhatsAppMessage> sendMessage({
    required String recipientId,
    required String content,
    String? referencedMessageId,
  }) async {
    try {
      final data = <String, dynamic>{
        'content': content,
        'messageType': 'text',
      };
      if (referencedMessageId != null) {
        data['referencedMessageId'] = referencedMessageId;
      }

      final response = await _apiService.post(
        '/api/whatsapp/messages/$recipientId',
        data: data,
      );

      return WhatsAppMessage.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Future<WhatsAppMessage> sendMediaMessage(
    String contactId,
    File file, {
    String? caption,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
        if (caption != null && caption.isNotEmpty) 'content': caption,
      });

      final response = await _apiService.dio.post(
        '/api/whatsapp/media/$contactId',
        data: formData,
      );

      return WhatsAppMessage.fromJson(response.data['data']['record']);
    } catch (e) {
      throw Exception('Failed to send media: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getAnalytics({
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/whatsapp/analytics',
        params: {'fromDate': fromDate, 'toDate': toDate},
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load analytics: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final response = await _apiService.get('/api/whatsapp/templates');
      final data = response.data['data'] ?? {};
      final records = data['records'] as List<dynamic>? ?? [];
      return records.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load templates: ${e.toString()}');
    }
  }

  Future<WhatsAppMessage> sendTemplateMessage({
    required String templateName,
    required String language,
    required List<Map<String, dynamic>> tos,
    List<Map<String, dynamic>>? components,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/whatsapp/template-message',
        data: {
          'templateName': templateName,
          'language': language,
          'tos': tos,
          if (components != null) 'components': components,
        },
      );
      return WhatsAppMessage.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to send template: ${e.toString()}');
    }
  }

  Future<void> markAsRead(String recipientId) async {
    try {
      await _apiService.put('/api/whatsapp/messages/$recipientId/read');
    } catch (e) {
      throw Exception('Failed to mark as read: ${e.toString()}');
    }
  }
}
