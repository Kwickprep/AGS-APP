import '../widgets/generic/generic_model.dart';

class CompanyModel implements GenericModel {
  @override
  final String id;
  final String name;
  final String email;
  final String website;
  final String industry;
  final String employees;
  final String turnover;
  final String gstNumber;
  final String country;
  final String state;
  final String city;
  final String isActive;
  final List<UserInfo> users;
  @override
  final String createdBy;
  @override
  final String createdAt;
  final String createdInfo;
  final String? updatedInfo;
  final List<CompanyAction> actions;

  CompanyModel({
    required this.id,
    required this.name,
    required this.email,
    required this.website,
    required this.industry,
    required this.employees,
    required this.turnover,
    required this.gstNumber,
    required this.country,
    required this.state,
    required this.city,
    required this.isActive,
    required this.users,
    required this.createdBy,
    required this.createdAt,
    this.createdInfo = '',
    this.updatedInfo,
    required this.actions,
  });

  @override
  dynamic getFieldValue(String fieldKey) {
    switch (fieldKey) {
      case 'id':
        return id;
      case 'name':
        return name;
      case 'email':
        return email;
      case 'website':
        return website;
      case 'industry':
        return industry;
      case 'employees':
        return employees;
      case 'turnover':
        return turnover;
      case 'gstNumber':
        return gstNumber;
      case 'country':
        return country;
      case 'state':
        return state;
      case 'city':
        return city;
      case 'isActive':
        return isActive;
      case 'createdBy':
        return createdBy;
      case 'createdAt':
        return createdAt;
      default:
        return null;
    }
  }

  // Helper function to extract string value from either string or object
  static String extractString(dynamic value) {
    if (value == null) return '-';
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      return value['name']?.toString() ?? value['id']?.toString() ?? '-';
    }
    return value.toString();
  }

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    // Extract ID from actions if not directly provided
    String extractedId = '';
    if (json['actions'] != null && (json['actions'] as List).isNotEmpty) {
      final firstAction = json['actions'][0];
      if (firstAction['routerLink'] != null) {
        final routerLink = firstAction['routerLink'] as String;
        final parts = routerLink.split('/');
        if (parts.length > 2) {
          extractedId = parts.last;
        }
      }
    }

    return CompanyModel(
      id: json['id'] ?? extractedId,
      name: extractString(json['name']),
      email: extractString(json['email']),
      website: extractString(json['website']),
      industry: extractString(json['industry']),
      employees: extractString(json['employees']),
      turnover: extractString(json['turnover']),
      gstNumber: extractString(json['gstNumber']),
      country: extractString(json['country']),
      state: extractString(json['state']),
      city: extractString(json['city']),
      isActive: extractString(json['isActive']),
      users: (json['users'] as List<dynamic>?)
              ?.map((e) => UserInfo.fromJson(e))
              .toList() ??
          [],
      createdBy: extractString(json['createdBy']),
      createdAt: extractString(json['createdAt']),
      createdInfo: extractString(json['createdInfo']),
      updatedInfo: json['updatedInfo']?.toString(),
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => CompanyAction.fromJson(e))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'website': website,
      'industry': industry,
      'employees': employees,
      'turnover': turnover,
      'gstNumber': gstNumber,
      'country': country,
      'state': state,
      'city': city,
      'isActive': isActive,
      'users': users.map((e) => e.toJson()).toList(),
      'createdBy': createdBy,
      'createdAt': createdAt,
      if (createdInfo.isNotEmpty) 'createdInfo': createdInfo,
      if (updatedInfo != null) 'updatedInfo': updatedInfo,
    };
  }

  // Check if active (convert string to bool)
  bool get isActiveStatus {
    return isActive.toLowerCase() == 'active' || isActive == 'true';
  }
}

class UserInfo {
  final String id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String company;
  final String department;
  final String designation;
  final String division;
  final String influenceType;
  final String employeeCode;
  final String groups;
  final String isActive;
  final bool isWhatsapp;
  final String isAcknowledged;
  final String createdBy;
  final String createdAt;

  UserInfo({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.company,
    required this.department,
    required this.designation,
    required this.division,
    required this.influenceType,
    required this.employeeCode,
    required this.groups,
    required this.isActive,
    required this.isWhatsapp,
    required this.isAcknowledged,
    required this.createdBy,
    required this.createdAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? '',
      firstName: CompanyModel.extractString(json['firstName']),
      middleName: CompanyModel.extractString(json['middleName']),
      lastName: CompanyModel.extractString(json['lastName']),
      email: CompanyModel.extractString(json['email']),
      phone: CompanyModel.extractString(json['phone']),
      role: CompanyModel.extractString(json['role']),
      company: CompanyModel.extractString(json['company']),
      department: CompanyModel.extractString(json['department']),
      designation: CompanyModel.extractString(json['designation']),
      division: CompanyModel.extractString(json['division']),
      influenceType: CompanyModel.extractString(json['influenceType']),
      employeeCode: CompanyModel.extractString(json['employeeCode']),
      groups: CompanyModel.extractString(json['groups']),
      isActive: CompanyModel.extractString(json['isActive']),
      isWhatsapp: json['isWhatsapp'] ?? false,
      isAcknowledged: CompanyModel.extractString(json['isAcknowledged']),
      createdBy: CompanyModel.extractString(json['createdBy']),
      createdAt: CompanyModel.extractString(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'company': company,
      'department': department,
      'designation': designation,
      'division': division,
      'influenceType': influenceType,
      'employeeCode': employeeCode,
      'groups': groups,
      'isActive': isActive,
      'isWhatsapp': isWhatsapp,
      'isAcknowledged': isAcknowledged,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  String get fullName {
    final parts = [firstName, middleName, lastName]
        .where((part) => part.isNotEmpty && part != '-')
        .toList();
    return parts.isEmpty ? 'N/A' : parts.join(' ');
  }
}

class CompanyAction {
  final String icon;
  final String type;
  final String? routerLink;
  final String? deleteEndpoint;
  final bool isDisabled;
  final String tooltip;

  CompanyAction({
    required this.icon,
    required this.type,
    this.routerLink,
    this.deleteEndpoint,
    required this.isDisabled,
    required this.tooltip,
  });

  factory CompanyAction.fromJson(Map<String, dynamic> json) {
    return CompanyAction(
      icon: json['icon'] ?? '',
      type: json['type'] ?? '',
      routerLink: json['routerLink'],
      deleteEndpoint: json['deleteEndpoint'],
      isDisabled: json['isDisabled'] ?? false,
      tooltip: json['tooltip'] ?? '',
    );
  }
}

class CompanyResponse {
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final List<CompanyModel> records;

  CompanyResponse({
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.records,
  });

  factory CompanyResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return CompanyResponse(
      total: data['total'] ?? 0,
      page: data['page'] ?? 1,
      take: data['take'] ?? 20,
      totalPages: data['totalPages'] ?? 1,
      records: (data['records'] as List<dynamic>?)
              ?.map((e) => CompanyModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
