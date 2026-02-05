import 'dart:convert';
import 'package:get_it/get_it.dart';
import '../models/activity_model.dart';
import '../widgets/generic/generic_model.dart';
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
        'filters': jsonEncode(filters),
        'isPageLayout': 'true',
      };

      final response = await _apiService.get(
        '/api/activities',
        params: queryParams,
      );

      return ActivityResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load activities: ${e.toString()}');
    }
  }

  Future<GenericResponse<ActivityModel>> getData({
    required int page,
    required int take,
    required String search,
    required String sortBy,
    required String sortOrder,
  }) async {
    final response = await getActivities(
      page: page,
      take: take,
      search: search,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    return GenericResponse<ActivityModel>(
      total: response.total,
      page: response.page,
      take: response.take,
      totalPages: response.totalPages,
      records: response.records,
    );
  }

  Future<bool> deleteActivity(String id) async {
    try {
      await _apiService.delete('/api/activities/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete activity: ${e.toString()}');
    }
  }

  Future<void> deleteData(String id) async {
    await deleteActivity(id);
  }

  Future<Map<String, dynamic>> createActivity(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/api/activities', data: data);
      // Return the full record data including body field
      return response.data['data']['record'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create activity: ${e.toString()}');
    }
  }

  Future<ActivityModel> updateActivity(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/api/activities/$id', data: data);
      return ActivityModel.fromJson(response.data['data']['record']);
    } catch (e) {
      throw Exception('Failed to update activity: ${e.toString()}');
    }
  }

  // Get activity types for dropdown
  Future<List<ActivityTypeModel>> getActivityTypes() async {
    try {
      final response = await _apiService.get('/api/activity-types');

      final data = response.data['data'] as Map<String, dynamic>;
      final records = data['records'] as List<dynamic>;

      return records.map((record) => ActivityTypeModel.fromJson(record)).toList();
    } catch (e) {
      throw Exception('Failed to load activity types: ${e.toString()}');
    }
  }

  // Get inquiries for dropdown
  Future<List<InquiryDropdownModel>> getInquiries() async {
    try {
      final response = await _apiService.get('/api/inquiries');

      final data = response.data['data'] as Map<String, dynamic>;
      final records = data['records'] as List<dynamic>;

      return records.map((record) => InquiryDropdownModel.fromJson(record)).toList();
    } catch (e) {
      throw Exception('Failed to load inquiries: ${e.toString()}');
    }
  }

  // Get active companies for dropdown
  Future<List<CompanyDropdownModel>> getActiveCompanies() async {
    try {
      final response = await _apiService.get(
        '/api/companies',
        params: {
          'filters': '{"filters":{"isActive":true}}',
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final records = data['records'] as List<dynamic>;

      return records.map((record) => CompanyDropdownModel.fromJson(record)).toList();
    } catch (e) {
      throw Exception('Failed to load companies: ${e.toString()}');
    }
  }

  // Get active companies with page layout (includes users)
  Future<List<CompanyDropdownModel>> getActiveCompaniesWithUsers() async {
    try {
      final response = await _apiService.get(
        '/api/companies',
        params: {
          'filters': '{"filters":{"isActive":true}}',
          'isPageLayout': 'true',
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final records = data['records'] as List<dynamic>;

      return records.map((record) => CompanyDropdownModel.fromJson(record)).toList();
    } catch (e) {
      throw Exception('Failed to load companies with users: ${e.toString()}');
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
}

// Activity Type Model
class ActivityTypeModel {
  final String id;
  final String name;
  final bool isActive;
  final bool isDefault;

  ActivityTypeModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.isDefault,
  });

  factory ActivityTypeModel.fromJson(Map<String, dynamic> json) {
    return ActivityTypeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? false,
      isDefault: json['isDefault'] ?? false,
    );
  }
}

// Inquiry Dropdown Model
class InquiryDropdownModel {
  final String id;
  final String name;
  final String? companyId;
  final String? contactUserId;

  InquiryDropdownModel({
    required this.id,
    required this.name,
    this.companyId,
    this.contactUserId,
  });

  factory InquiryDropdownModel.fromJson(Map<String, dynamic> json) {
    return InquiryDropdownModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      companyId: json['companyId'],
      contactUserId: json['contactUserId'],
    );
  }
}

// Company Dropdown Model
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

// User Dropdown Model
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
