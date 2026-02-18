import 'package:get_it/get_it.dart';
import '../models/whatsapp_models.dart';
import 'api_service.dart';

class WhatsAppAutoReplyService {
  final ApiService _api = GetIt.I<ApiService>();

  Future<WhatsAppAutoReplyResponse> getAll({
    int page = 1,
    int take = 25,
    String search = '',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final res = await _api.get('/api/whatsapp-auto-replies', params: {
        'page': page.toString(),
        'take': take.toString(),
        'search': search,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      });
      return WhatsAppAutoReplyResponse.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load auto-replies: $e');
    }
  }

  Future<WhatsAppAutoReplyModel> create(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/api/whatsapp-auto-replies', data: data);
      return WhatsAppAutoReplyModel.fromJson(res.data['data']['record']);
    } catch (e) {
      throw Exception('Failed to create auto-reply: $e');
    }
  }

  Future<WhatsAppAutoReplyModel> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('/api/whatsapp-auto-replies/$id', data: data);
      return WhatsAppAutoReplyModel.fromJson(res.data['data']['record']);
    } catch (e) {
      throw Exception('Failed to update auto-reply: $e');
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _api.delete('/api/whatsapp-auto-replies/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete auto-reply: $e');
    }
  }
}
