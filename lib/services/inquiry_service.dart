import 'dart:convert';
import 'package:get_it/get_it.dart';
import '../models/inquiry_model.dart';
import '../widgets/generic/generic_model.dart';
import 'api_service.dart';

class InquiryService{
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
        'filters': jsonEncode(filters),
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

  // Get active companies for dropdown
  Future<List<CompanyDropdownModel>> getActiveCompanies() async {
    try {
      final response = await _apiService.get(
        '/api/companies',
        params: {
          'filters': '{"isActive":true}',
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final records = data['records'] as List<dynamic>;

      return records.map((record) => CompanyDropdownModel.fromJson(record)).toList();
    } catch (e) {
      throw Exception('Failed to load companies: ${e.toString()}');
    }
  }

  // Get active users for dropdown
  Future<List<UserDropdownModel>> getActiveUsers() async {
    try {
      final response = await _apiService.get(
        '/api/users',
        params: {
          'filters': '{"isActive":true}',
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final records = data['records'] as List<dynamic>;

      return records.map((record) => UserDropdownModel.fromJson(record)).toList();
    } catch (e) {
      throw Exception('Failed to load users: ${e.toString()}');
    }
  }

  // Get users by company ID
  Future<List<UserDropdownModel>> getUsersByCompany(String companyId) async {
    try {
      final response = await _apiService.get(
        '/api/users',
        params: {
          'filters': '{"isActive":true,"companyId":"$companyId"}',
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final records = data['records'] as List<dynamic>;

      return records.map((record) => UserDropdownModel.fromJson(record)).toList();
    } catch (e) {
      throw Exception('Failed to load users: ${e.toString()}');
    }
  }

  // Create inquiry
  Future<InquiryModel> createInquiry(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/api/inquiries', data: data);
      return InquiryModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to create inquiry: ${e.toString()}');
    }
  }

  // Update inquiry
  Future<InquiryModel> updateInquiry(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/api/inquiries/$id', data: data);
      return InquiryModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update inquiry: ${e.toString()}');
    }
  }
}

// Dropdown models
class CompanyDropdownModel {
  final String id;
  final String name;
  final List<UserDropdownModel> users;

  CompanyDropdownModel({
    required this.id,
    required this.name,
    required this.users,
  });

  factory CompanyDropdownModel.fromJson(Map<String, dynamic> json) {
    return CompanyDropdownModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      users: (json['users'] as List<dynamic>?)
          ?.map((user) => UserDropdownModel.fromJson(user))
          .toList() ?? [],
    );
  }
}

class UserDropdownModel {
  final String id;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String phoneNumber;
  final String? companyId;

  UserDropdownModel({
    required this.id,
    required this.firstName,
    this.middleName,
    this.lastName,
    required this.phoneNumber,
    this.companyId,
  });

  String get fullName {
    final parts = [
      firstName,
      if (middleName != null && middleName!.isNotEmpty) middleName,
      if (lastName != null && lastName!.isNotEmpty) lastName,
    ];
    return parts.join(' ');
  }

  factory UserDropdownModel.fromJson(Map<String, dynamic> json) {
    return UserDropdownModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'] ?? '',
      companyId: json['companyId'],
    );
  }
}
