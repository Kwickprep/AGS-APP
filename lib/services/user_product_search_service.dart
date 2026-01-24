import 'package:get_it/get_it.dart';
import '../models/user_product_search_model.dart';
import 'api_service.dart';

class UserProductSearchService {
  final ApiService _apiService = GetIt.I<ApiService>();

  static const String _activityTypeId = '68e77f49728d6edb593273cc';

  /// Search products with a text query and/or document IDs
  Future<UserProductSearchResponse> searchProducts({
    required String query,
    List<String> documentIds = const [],
  }) async {
    try {
      final data = {
        'activityTypeId': _activityTypeId,
        'body': {
          'inputText': query,
          'documentIds': documentIds,
          'stage': 'INITIAL',
        },
      };

      final response = await _apiService.post('/api/activities', data: data);

      return UserProductSearchResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to search products: ${e.toString()}');
    }
  }

  /// Select a theme for the product search
  Future<UserProductSearchResponse> selectTheme({
    required String activityId,
    required AISuggestedTheme theme,
  }) async {
    try {
      final data = {
        'body': {
          'selectedTheme': {
            'id': theme.id,
            'name': theme.name,
            'reason': theme.reason,
          },
        },
      };

      final response = await _apiService.put(
        '/api/activity-types/$activityId',
        data: data,
      );

      return UserProductSearchResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to select theme: ${e.toString()}');
    }
  }

  /// Select a category for the product search
  Future<UserProductSearchResponse> selectCategory({
    required String activityId,
    required AISuggestedCategory category,
  }) async {
    try {
      final data = {
        'body': {
          'selectedCategory': {
            'id': category.id,
            'name': category.name,
            'description': category.description,
          },
        },
      };

      final response = await _apiService.put(
        '/api/activity-types/$activityId',
        data: data,
      );

      return UserProductSearchResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to select category: ${e.toString()}');
    }
  }
}
