import 'package:get_it/get_it.dart';
import '../models/inquiry_model.dart';
import '../widgets/generic/generic_model.dart';
import '../widgets/generic/generic_list_bloc.dart';
import 'api_service.dart';

class InquiryService implements GenericListService<InquiryModel> {
  final ApiService _apiService = GetIt.I<ApiService>();

  Future<InquiryResponse> getInquiries({
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
        '/api/inquiries',
        params: queryParams,
      );

      return InquiryResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load inquiries: ${e.toString()}');
    }
  }

  @override
  Future<GenericResponse<InquiryModel>> getData({
    required int page,
    required int take,
    required String search,
    required String sortBy,
    required String sortOrder,
  }) async {
    final response = await getInquiries(
      page: page,
      take: take,
      search: search,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    return GenericResponse<InquiryModel>(
      total: response.total,
      page: response.page,
      take: response.take,
      totalPages: response.totalPages,
      records: response.records,
    );
  }

  Future<bool> deleteInquiry(String id) async {
    try {
      await _apiService.delete('/api/inquiries/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete inquiry: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteData(String id) async {
    await deleteInquiry(id);
  }
}
