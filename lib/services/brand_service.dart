import 'package:get_it/get_it.dart';
import '../models/brand_model.dart';
import 'api_service.dart';

class BrandService {
  final ApiService _apiService = GetIt.I<ApiService>();

  Future<BrandResponse> getBrands({
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
        '/api/brands',
        params: queryParams,
      );

      return BrandResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load brands: ${e.toString()}');
    }
  }

  Future<bool> deleteBrand(String id) async {
    try {
      await _apiService.delete('/api/brands/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete brand: ${e.toString()}');
    }
  }
}