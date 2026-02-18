import 'package:get_it/get_it.dart';
import '../models/whatsapp_models.dart';
import 'api_service.dart';

class WhatsAppTemplateCategoryService {
  final ApiService _api = GetIt.I<ApiService>();

  Future<WhatsAppTemplateCategoryResponse> getAll({
    int page = 1,
    int take = 25,
    String search = '',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final res = await _api.get('/api/whatsapp-template-categories', params: {
        'page': page.toString(),
        'take': take.toString(),
        'search': search,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      });
      return WhatsAppTemplateCategoryResponse.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to load template categories: $e');
    }
  }

  Future<WhatsAppTemplateCategoryModel> create(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/api/whatsapp-template-categories', data: data);
      return WhatsAppTemplateCategoryModel.fromJson(res.data['data']['record']);
    } catch (e) {
      throw Exception('Failed to create template category: $e');
    }
  }

  Future<WhatsAppTemplateCategoryModel> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('/api/whatsapp-template-categories/$id', data: data);
      return WhatsAppTemplateCategoryModel.fromJson(res.data['data']['record']);
    } catch (e) {
      throw Exception('Failed to update template category: $e');
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _api.delete('/api/whatsapp-template-categories/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete template category: $e');
    }
  }
}
