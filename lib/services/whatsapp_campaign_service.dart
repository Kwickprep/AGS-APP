import 'package:get_it/get_it.dart';
import '../models/whatsapp_models.dart';
import 'api_service.dart';

class WhatsAppCampaignService {
  final ApiService _api = GetIt.I<ApiService>();

  Future<WhatsAppCampaignResponse> getAll({
    int page = 1,
    int take = 25,
    String search = '',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final res = await _api.get('/api/whatsapp-campaigns', params: {
        'page': page.toString(),
        'take': take.toString(),
        'search': search,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'isPageLayout': 'true',
      });
      return WhatsAppCampaignResponse.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load campaigns: $e');
    }
  }

  Future<WhatsAppCampaignModel> create(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/api/whatsapp-campaigns', data: data);
      return WhatsAppCampaignModel.fromJson(res.data['data']['record']);
    } catch (e) {
      throw Exception('Failed to create campaign: $e');
    }
  }

  Future<WhatsAppCampaignModel> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('/api/whatsapp-campaigns/$id', data: data);
      return WhatsAppCampaignModel.fromJson(res.data['data']['record']);
    } catch (e) {
      throw Exception('Failed to update campaign: $e');
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _api.delete('/api/whatsapp-campaigns/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete campaign: $e');
    }
  }

  Future<Map<String, dynamic>> execute(String id) async {
    try {
      final res = await _api.post('/api/whatsapp-campaigns/$id/execute');
      return res.data['data'] ?? {};
    } catch (e) {
      throw Exception('Failed to execute campaign: $e');
    }
  }

  Future<Map<String, dynamic>> stop(String id) async {
    try {
      final res = await _api.post('/api/whatsapp-campaigns/$id/stop');
      return res.data['data'] ?? {};
    } catch (e) {
      throw Exception('Failed to stop campaign: $e');
    }
  }
}
