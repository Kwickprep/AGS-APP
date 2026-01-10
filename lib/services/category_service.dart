import 'dart:convert';
import 'package:get_it/get_it.dart';
import '../models/category_model.dart';
import '../widgets/generic/generic_model.dart';
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
        'filters': jsonEncode(filters),
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

  @override
  Future<GenericResponse<CategoryModel>> getData({
    required int page,
    required int take,
    required String search,
    required String sortBy,
    required String sortOrder,
  }) async {
    final response = await getCategories(
      page: page,
      take: take,
      search: search,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    return GenericResponse<CategoryModel>(
      total: response.total,
      page: response.page,
      take: response.take,
      totalPages: response.totalPages,
      records: response.records,
    );
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _apiService.delete('/api/categories/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete category: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteData(String id) async {
    await deleteCategory(id);
  }

  Future<void> createCategory({
    required String name,
    required bool isActive,
    String? description,
  }) async {
    try {
      final data = {
        'name': name,
        'isActive': isActive,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      await _apiService.post('/api/categories', data: data);
    } catch (e) {
      throw Exception('Failed to create category: ${e.toString()}');
    }
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required bool isActive,
    required String createdBy,
    required String createdAt,
    required String updatedBy,
    required String updatedAt,
    String? description,
  }) async {
    try {
      final data = {
        'id': id,
        'name': name,
        'isActive': isActive,
        'createdBy': createdBy,
        'createdAt': createdAt,
        'updatedBy': updatedBy,
        'updatedAt': updatedAt,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      await _apiService.put('/api/categories/$id', data: data);
    } catch (e) {
      throw Exception('Failed to update category: ${e.toString()}');
    }
  }

  /// Get active categories for dropdown
  Future<List<CategoryModel>> getActiveCategories() async {
    try {
      final response = await getCategories(
        page: 1,
        take: 1000,
        filters: {'isActive': true},
      );
      return response.records;
    } catch (e) {
      throw Exception('Failed to load active categories: ${e.toString()}');
    }
  }
}