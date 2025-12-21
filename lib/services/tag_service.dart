import 'package:get_it/get_it.dart';
import '../models/tag_model.dart';
import '../widgets/generic/generic_model.dart';
import 'api_service.dart';

class TagService  {
  final ApiService _apiService = GetIt.I<ApiService>();

  Future<TagResponse> getTags({
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
      };

      final response = await _apiService.get(
        '/api/tags',
        params: queryParams,
      );

      return TagResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load tags: ${e.toString()}');
    }
  }

  @override
  Future<GenericResponse<TagModel>> getData({
    required int page,
    required int take,
    required String search,
    required String sortBy,
    required String sortOrder,
  }) async {
    final response = await getTags(
      page: page,
      take: take,
      search: search,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    return GenericResponse<TagModel>(
      total: response.total,
      page: response.page,
      take: response.take,
      totalPages: response.totalPages,
      records: response.records,
    );
  }

  Future<bool> deleteTag(String id) async {
    try {
      await _apiService.delete('/api/tags/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete tag: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteData(String id) async {
    await deleteTag(id);
  }
}
