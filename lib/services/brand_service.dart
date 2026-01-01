import 'dart:convert';
import 'package:get_it/get_it.dart';
import '../models/brand_model.dart';
import '../widgets/generic/generic_model.dart';
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
        'filters': jsonEncode(filters),
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

  Future<GenericResponse<BrandModel>> getData({
    required int page,
    required int take,
    required String search,
    required String sortBy,
    required String sortOrder,
  }) async {
    final response = await getBrands(
      page: page,
      take: take,
      search: search,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    return GenericResponse<BrandModel>(
      total: response.total,
      page: response.page,
      take: response.take,
      totalPages: response.totalPages,
      records: response.records,
    );
  }

  Future<bool> deleteBrand(String id) async {
    try {
      await _apiService.delete('/api/brands/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete brand: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteData(String id) async {
    await deleteBrand(id);
  }

  Future<void> createBrand({
    required String name,
    required bool isActive,
    double? aop,
    double? discount,
  }) async {
    try {
      final data = {
        'name': name,
        'isActive': isActive,
        if (aop != null) 'aop': aop,
        if (discount != null) 'discount': discount,
      };

      await _apiService.post('/api/brands', data: data);
    } catch (e) {
      throw Exception('Failed to create brand: ${e.toString()}');
    }
  }

  Future<void> updateBrand({
    required String id,
    required String name,
    required bool isActive,
    required String createdBy,
    required String createdAt,
    required String updatedBy,
    required String updatedAt,
    double? aop,
    double? discount,
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
        if (aop != null) 'aop': aop,
        if (discount != null) 'discount': discount,
      };

      await _apiService.put('/api/brands/$id', data: data);
    } catch (e) {
      throw Exception('Failed to update brand: ${e.toString()}');
    }
  }
}