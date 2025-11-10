import 'package:get_it/get_it.dart';
import '../models/activity_model.dart';
import 'api_service.dart';

class ActivityService {
  final ApiService _apiService = GetIt.I<ApiService>();

  Future<ActivityResponse> getActivities({
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

      print('ActivityService: Calling GET /api/activities with params: $queryParams');
      final response = await _apiService.get(
        '/api/activities',
        params: queryParams,
      );

      print('ActivityService: Response received: ${response.data}');
      return ActivityResponse.fromJson(response.data);
    } catch (e) {
      print('ActivityService: Error - $e');
      throw Exception('Failed to load activities: ${e.toString()}');
    }
  }

  Future<bool> deleteActivity(String id) async {
    try {
      await _apiService.delete('/api/activities/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete activity: ${e.toString()}');
    }
  }

  Future<ActivityModel> createActivity(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/api/activities', data: data);
      return ActivityModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to create activity: ${e.toString()}');
    }
  }

  Future<ActivityModel> updateActivity(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.get('/api/activities/$id', params: data);
      return ActivityModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update activity: ${e.toString()}');
    }
  }
}
