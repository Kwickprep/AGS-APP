import 'dart:convert';
import 'package:get_it/get_it.dart';
import '../models/product_model.dart';
import '../widgets/generic/generic_model.dart';
import 'api_service.dart';

class ProductService  {
  final ApiService _apiService = GetIt.I<ApiService>();

  Future<GenericResponse<ProductModel>> getData({
    required int page,
    required int take,
    required String search,
    required String sortBy,
    required String sortOrder,
  }) async {
    return getProducts(
      page: page,
      take: take,
      search: search,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<void> deleteData(String id) async {
    return deleteProduct(id);
  }

  /// Get products with pagination, search, sorting, and filters
  Future<GenericResponse<ProductModel>> getProducts({
    int page = 1,
    int take = 20,
    String search = '',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    Map<String, dynamic>? filters,
    bool isPageLayout = false,
  }) async {
    try {
      // Build query parameters
      final params = {
        'page': page.toString(),
        'take': take.toString(),
        'search': search,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'filters': filters != null ? jsonEncode(filters) : '{}',
        'isPageLayout': isPageLayout.toString(),
      };

      final response = await _apiService.get('/api/products', params: params);

      if (response.statusCode == 200) {
        final productResponse = ProductResponse.fromJson(response.data);
        // Convert ProductResponse to GenericResponse
        return GenericResponse<ProductModel>(
          total: productResponse.total,
          page: productResponse.page,
          take: productResponse.take,
          totalPages: productResponse.totalPages,
          records: productResponse.records,
        );
      } else {
        throw Exception(
            'Failed to load products: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  /// Get single product by ID
  Future<ProductModel> getProduct(String id) async {
    try {
      final response = await _apiService.get('/api/products/$id');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return ProductModel.fromJson(data);
      } else {
        throw Exception(
            'Failed to load product: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load product: $e');
    }
  }

  /// Get product with page layout (includes theme relevance scores)
  Future<List<Map<String, dynamic>>> getProductThemeScores(String id) async {
    try {
      final response = await _apiService.get(
        '/api/products/$id',
        params: {'isPageLayout': 'true'},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final record = data['record'];
        final themes = record['themes'] as List<dynamic>? ?? [];
        return themes.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            'Failed to load product themes: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to load product themes: $e');
    }
  }

  /// Create new product
  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/api/products', data: data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data['data'];
        return ProductModel.fromJson(responseData);
      } else {
        throw Exception(
            'Failed to create product: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  /// Update existing product
  Future<ProductModel> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/api/products/$id', data: data);

      if (response.statusCode == 200) {
        final responseData = response.data['data'];
        return ProductModel.fromJson(responseData);
      } else {
        throw Exception(
            'Failed to update product: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Delete product
  Future<void> deleteProduct(String id) async {
    try {
      final response = await _apiService.delete('/api/products/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
            'Failed to delete product: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Search products
  Future<GenericResponse<ProductModel>> searchProducts(String query, {int page = 1, int take = 20}) async {
    return getProducts(
      page: page,
      take: take,
      search: query,
    );
  }
}
