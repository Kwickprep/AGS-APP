import 'dart:convert';
import 'package:get_it/get_it.dart';
import '../models/user_screen_model.dart';
import '../models/user_insights_model.dart';
import '../widgets/generic/generic_model.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService = GetIt.I<ApiService>();

  Future<UserScreenResponse> getUsers({
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
        'search': search.trim().isNotEmpty ? search.trim() : null,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'filters': jsonEncode(filters),
        'isPageLayout': 'true',
      };

      final response = await _apiService.get('/api/users', params: queryParams);

      return UserScreenResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load users: ${e.toString()}');
    }
  }

  @override
  Future<GenericResponse<UserScreenModel>> getData({
    required int page,
    required int take,
    required String search,
    required String sortBy,
    required String sortOrder,
  }) async {
    final response = await getUsers(
      page: page,
      take: take,
      search: search,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    return GenericResponse<UserScreenModel>(
      total: response.total,
      page: response.page,
      take: response.take,
      totalPages: response.totalPages,
      records: response.records,
    );
  }

  Future<bool> deleteUser(String id) async {
    try {
      await _apiService.delete('/api/users/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteData(String id) async {
    await deleteUser(id);
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/api/users', data: data);
      return response.data['data']['record'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getUserById(String id) async {
    try {
      final response = await _apiService.get('/api/users/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch user: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateUser(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put('/api/users/$id', data: data);
      return response.data['data']['record'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getUserInsights(String id) async {
    try {
      final response = await _apiService.get('/api/users/$id/insights');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch user insights: ${e.toString()}');
    }
  }

  // Get users by company IDs (for Select Users section in Admin/Employee role)
  Future<List<Map<String, dynamic>>> getUsersByCompanies(
    List<String> companyIds,
  ) async {
    try {
      if (companyIds.isEmpty) return [];

      // Add company filter to fetch only users from selected companies
      final filters = {
        'companyIds': companyIds,
      };

      final queryParams = {
        'page': '1',
        'take': '1000', // Fetch up to 1000 users to avoid pagination issues
        'search': '',
        'sortBy': 'firstName',
        'sortOrder': 'asc',
        'filters': jsonEncode(filters),
        'isPageLayout': 'true',
      };

      final response = await _apiService.get('/api/users', params: queryParams);

      final records = response.data['data']['records'] as List<dynamic>;

      // Return all users (already filtered by API)
      return records.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to load users by companies: ${e.toString()}');
    }
  }
}
