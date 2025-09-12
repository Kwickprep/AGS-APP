import 'package:get_it/get_it.dart';
import '../models/category_model.dart';
import 'api_service.dart';

class CategoryService {
  final ApiService _apiService = GetIt.I<ApiService>();

  Future<CategoryResponse> getCategories({
    int page = 1,
    int take = 20,
    String search = '',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    Map<String, dynamic> filters = const {},
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'take': take.toString(),
        'search': search,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'filters': '{}',
        'isPageLayout': 'true',
      };

      final response = await _apiService.get(
        '/api/categories',
        params: queryParams,
      );

      return CategoryResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load categories: ${e.toString()}');
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _apiService.delete('/api/categories/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete category: ${e.toString()}');
    }
  }
}