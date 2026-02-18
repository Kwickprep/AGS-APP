import 'dart:convert';
import 'package:get_it/get_it.dart';
import '../models/company_model.dart';
import '../widgets/generic/generic_model.dart';
import 'api_service.dart';

class CompanyService {
  final ApiService _apiService = GetIt.I<ApiService>();

  Future<CompanyResponse> getCompanies({
    int page = 1,
    int take = 20,
    String search = '',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    Map<String, dynamic> filters = const {},
  }) async {
    try {
      // Build the filters object matching the API format
      final filterObject = {
        'page': page,
        'take': take,
        'search': search.trim(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'filters': jsonEncode(filters),
      };

      final queryParams = {
        'filters': jsonEncode(filterObject),
      };

      final response =
          await _apiService.get('/api/companies', params: queryParams);

      return CompanyResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load companies: ${e.toString()}');
    }
  }

  Future<GenericResponse<CompanyModel>> getData({
    required int page,
    required int take,
    required String search,
    required String sortBy,
    required String sortOrder,
  }) async {
    final response = await getCompanies(
      page: page,
      take: take,
      search: search,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    return GenericResponse<CompanyModel>(
      total: response.total,
      page: response.page,
      take: response.take,
      totalPages: response.totalPages,
      records: response.records,
    );
  }

  Future<bool> deleteCompany(String id) async {
    try {
      await _apiService.delete('/api/companies/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete company: ${e.toString()}');
    }
  }

  Future<void> deleteData(String id) async {
    await deleteCompany(id);
  }

  Future<Map<String, dynamic>> createCompany(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/api/companies', data: data);
      return response.data['data']['record'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create company: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getCompanyById(String id) async {
    try {
      final queryParams = {'isPageLayout': 'true'};
      final response =
          await _apiService.get('/api/companies/$id', params: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch company: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getCompanyFormConfig() async {
    try {
      final queryParams = {'isPageLayout': 'true'};
      final response =
          await _apiService.get('/api/companies/none', params: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch company form config: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getCompanyInsights(String id) async {
    try {
      final response = await _apiService.get('/api/companies/$id/insights');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch company insights: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateCompany(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put('/api/companies/$id', data: data);
      return response.data['data']['record'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update company: ${e.toString()}');
    }
  }
}
