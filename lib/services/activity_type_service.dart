import 'dart:convert';
import 'package:get_it/get_it.dart';
import '../models/activity_type_model.dart';
import '../models/form_page_layout_model.dart';
import '../widgets/generic/generic_model.dart';
import 'api_service.dart';

class ActivityTypeService {
  final ApiService _apiService = GetIt.I<ApiService>();

  Future<ActivityTypeResponse> getActivityTypes({
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
        '/api/activity-types',
        params: queryParams,
      );

      return ActivityTypeResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load activity types: ${e.toString()}');
    }
  }

  Future<GenericResponse<ActivityTypeModel>> getData({
    required int page,
    required int take,
    required String search,
    required String sortBy,
    required String sortOrder,
  }) async {
    final response = await getActivityTypes(
      page: page,
      take: take,
      search: search,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    return GenericResponse<ActivityTypeModel>(
      total: response.total,
      page: response.page,
      take: response.take,
      totalPages: response.totalPages,
      records: response.records,
    );
  }

  Future<bool> deleteActivityType(String id) async {
    try {
      await _apiService.delete('/api/activity-types/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete activity type: ${e.toString()}');
    }
  }

  Future<void> deleteData(String id) async {
    await deleteActivityType(id);
  }

  Future<void> createActivityType({
    required String name,
    required bool isActive,
  }) async {
    try {
      final data = {
        'id': '',
        'createdBy': '',
        'updatedBy': '',
        'createdAt': '',
        'updatedAt': '',
        'name': name,
        'isActive': isActive,
      };

      await _apiService.post('/api/activity-types', data: data);
    } catch (e) {
      throw Exception('Failed to create activity type: ${e.toString()}');
    }
  }

  Future<void> updateActivityType({
    required String id,
    required String name,
    required bool isActive,
    required String createdBy,
    required String createdAt,
    required String updatedBy,
    required String updatedAt,
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
      };

      await _apiService.put('/api/activity-types/$id', data: data);
    } catch (e) {
      throw Exception('Failed to update activity type: ${e.toString()}');
    }
  }

  /// Get active activity types for dropdown
  Future<List<ActivityTypeModel>> getActiveActivityTypes() async {
    try {
      final response = await getActivityTypes(
        page: 1,
        take: 1000,
        filters: {'isActive': true},
      );
      return response.records;
    } catch (e) {
      throw Exception('Failed to load active activity types: ${e.toString()}');
    }
  }

  /// Get form page layout for create/edit screen
  /// Use 'none' for create, or actual ID for edit
  Future<FormPageLayoutResponse> getFormPageLayout(String id) async {
    try {
      final queryParams = {'isPageLayout': 'true'};

      final response = await _apiService.get(
        '/api/activity-types/$id',
        params: queryParams,
      );

      return FormPageLayoutResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load form layout: ${e.toString()}');
    }
  }
}
