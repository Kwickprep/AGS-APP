import 'package:get_it/get_it.dart';
import '../models/theme_model.dart';
import '../widgets/generic/generic_model.dart';
import '../widgets/generic/generic_list_bloc.dart';
import 'api_service.dart';

class ThemeService implements GenericListService<ThemeModel> {
  final ApiService _apiService = GetIt.I<ApiService>();

  Future<ThemeResponse> getThemes({
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

      final response = await _apiService.get(
        '/api/themes',
        params: queryParams,
      );

      return ThemeResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load themes: ${e.toString()}');
    }
  }

  @override
  Future<GenericResponse<ThemeModel>> getData({
    required int page,
    required int take,
    required String search,
    required String sortBy,
    required String sortOrder,
  }) async {
    final response = await getThemes(
      page: page,
      take: take,
      search: search,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    return GenericResponse<ThemeModel>(
      total: response.total,
      page: response.page,
      take: response.take,
      totalPages: response.totalPages,
      records: response.records,
    );
  }

  Future<bool> deleteTheme(String id) async {
    try {
      await _apiService.delete('/api/themes/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete theme: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteData(String id) async {
    await deleteTheme(id);
  }
}