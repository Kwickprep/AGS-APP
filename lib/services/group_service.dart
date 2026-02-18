import 'dart:convert';
import 'package:get_it/get_it.dart';
import '../models/group_model.dart';
import '../models/contact_model.dart';
import '../widgets/generic/generic_model.dart';
import 'api_service.dart';

class GroupService {
  final ApiService _apiService = GetIt.I<ApiService>();

  Future<GroupResponse> getGroups({
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
      };

      final response = await _apiService.get(
        '/api/groups',
        params: queryParams,
      );

      return GroupResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load groups: ${e.toString()}');
    }
  }

  Future<GenericResponse<GroupModel>> getData({
    required int page,
    required int take,
    required String search,
    required String sortBy,
    required String sortOrder,
  }) async {
    final response = await getGroups(
      page: page,
      take: take,
      search: search,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    return GenericResponse<GroupModel>(
      total: response.total,
      page: response.page,
      take: response.take,
      totalPages: response.totalPages,
      records: response.records,
    );
  }

  Future<bool> deleteGroup(String id) async {
    try {
      await _apiService.delete('/api/groups/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete group: ${e.toString()}');
    }
  }

  Future<void> deleteData(String id) async {
    await deleteGroup(id);
  }

  Future<List<ContactModel>> getContacts() async {
    try {
      final response = await _apiService.get(
        '/api/groups/none',
        params: {'isPageLayout': 'true'},
      );

      final records = response.data['data']['context']['pageLayout']['body']
          ['form']['fields']['userIds']['records'] as List;

      return records.map((e) => ContactModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load contacts: ${e.toString()}');
    }
  }

  Future<bool> createGroup({
    required String name,
    required bool isActive,
    required String note,
    required List<String> userIds,
  }) async {
    try {
      await _apiService.post('/api/groups', data: {
        'name': name,
        'isActive': isActive,
        'note': note,
        'userIds': userIds,
      });
      return true;
    } catch (e) {
      throw Exception('Failed to create group: ${e.toString()}');
    }
  }

  Future<bool> updateGroup({
    required String id,
    required String name,
    required bool isActive,
    required String note,
    required List<String> userIds,
  }) async {
    try {
      await _apiService.put('/api/groups/$id', data: {
        'name': name,
        'isActive': isActive,
        'note': note,
        'userIds': userIds,
      });
      return true;
    } catch (e) {
      throw Exception('Failed to update group: ${e.toString()}');
    }
  }

  Future<List<String>> getGroupUserIds(String groupId) async {
    try {
      final response = await _apiService.get(
        '/api/groups/$groupId',
        params: {'isPageLayout': 'true'},
      );

      // Parse the response to extract user IDs
      final data = response.data['data'] ?? {};
      final context = data['context'] ?? {};
      final pageLayout = context['pageLayout'] ?? {};
      final body = pageLayout['body'] ?? {};
      final form = body['form'] ?? {};
      final fields = form['fields'] ?? {};
      final userIds = fields['userIds'] ?? {};
      final value = userIds['value'];

      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to load group details: ${e.toString()}');
    }
  }
}
