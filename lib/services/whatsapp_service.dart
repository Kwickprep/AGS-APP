import 'package:get_it/get_it.dart';
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
  }) async {
    try {
      final encodedParams = Uri.encodeComponent('{"limit":$limit}');

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
  }) async {
    try {
      final response = await _apiService.post(
        '/api/whatsapp/messages',
        data: {
          'recipientId': recipientId,
          'content': content,
          'messageType': 'text',
        },
      );

      return WhatsAppMessage.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
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
