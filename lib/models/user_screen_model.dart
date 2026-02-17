import '../widgets/generic/generic_model.dart';

class UserScreenModel implements GenericModel {
  @override
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
  final bool isWhatsapp;
  final String isAcknowledged;
  final String isActive;
  @override
  final String createdBy;
  @override
  final String createdAt;
  final String createdInfo;
  final String? updatedInfo;
  final List<UserAction> actions;
  final String? profilePictureUrl;

  UserScreenModel({
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
    required this.isWhatsapp,
    required this.isAcknowledged,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    this.createdInfo = '',
    this.updatedInfo,
    required this.actions,
    this.profilePictureUrl,
  });

  @override
  dynamic getFieldValue(String fieldKey) {
    switch (fieldKey) {
      case 'id':
        return id;
      case 'firstName':
        return firstName;
      case 'middleName':
        return middleName;
      case 'lastName':
        return lastName;
      case 'email':
        return email;
      case 'phone':
        return phone;
      case 'role':
        return role;
      case 'company':
        return company;
      case 'department':
        return department;
      case 'designation':
        return designation;
      case 'division':
        return division;
      case 'influenceType':
        return influenceType;
      case 'employeeCode':
        return employeeCode;
      case 'groups':
        return groups;
      case 'isWhatsapp':
        return isWhatsapp;
      case 'isAcknowledged':
        return isAcknowledged;
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
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      return value['name']?.toString() ?? value['id']?.toString() ?? '';
    }
    return value.toString();
  }

  factory UserScreenModel.fromJson(Map<String, dynamic> json) {
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

    return UserScreenModel(
      id: json['id'] ?? extractedId,
      firstName: extractString(json['firstName']),
      middleName: extractString(json['middleName']),
      lastName: extractString(json['lastName']),
      email: extractString(json['email']),
      phone: extractString(json['phone']),
      role: extractString(json['role']),
      company: extractString(json['company']),
      department: extractString(json['department']),
      designation: extractString(json['designation']),
      division: extractString(json['division']),
      influenceType: extractString(json['influenceType']),
      employeeCode: extractString(json['employeeCode']),
      groups: extractString(json['groups']),
      isWhatsapp: json['isWhatsapp'] ?? false,
      isAcknowledged: extractString(json['isAcknowledged']),
      isActive: extractString(json['isActive']),
      createdBy: extractString(json['createdBy']),
      createdAt: extractString(json['createdAt']),
      createdInfo: extractString(json['createdInfo']),
      updatedInfo: json['updatedInfo']?.toString(),
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => UserAction.fromJson(e))
              .toList() ??
          [],
      profilePictureUrl: json['profilePictureUrl'],
    );
  }

  @override
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
      'isWhatsapp': isWhatsapp,
      'isAcknowledged': isAcknowledged,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
      if (createdInfo.isNotEmpty) 'createdInfo': createdInfo,
      if (updatedInfo != null) 'updatedInfo': updatedInfo,
    };
  }

  // Get full name
  String get fullName {
    final parts = [firstName, middleName, lastName]
        .where((part) => part.isNotEmpty && part != '-')
        .toList();
    return parts.isEmpty ? 'N/A' : parts.join(' ');
  }

  // Check if active (convert string to bool)
  bool get isActiveStatus {
    return isActive.toLowerCase() == 'active' || isActive == 'true';
  }
}

class UserAction {
  final String icon;
  final String type;
  final String? routerLink;
  final String? deleteEndpoint;
  final bool isDisabled;
  final String tooltip;

  UserAction({
    required this.icon,
    required this.type,
    this.routerLink,
    this.deleteEndpoint,
    required this.isDisabled,
    required this.tooltip,
  });

  factory UserAction.fromJson(Map<String, dynamic> json) {
    return UserAction(
      icon: json['icon'] ?? '',
      type: json['type'] ?? '',
      routerLink: json['routerLink'],
      deleteEndpoint: json['deleteEndpoint'],
      isDisabled: json['isDisabled'] ?? false,
      tooltip: json['tooltip'] ?? '',
    );
  }
}

class UserScreenResponse {
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final List<UserScreenModel> records;

  UserScreenResponse({
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.records,
  });

  factory UserScreenResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return UserScreenResponse(
      total: data['total'] ?? 0,
      page: data['page'] ?? 1,
      take: data['take'] ?? 20,
      totalPages: data['totalPages'] ?? 1,
      records: (data['records'] as List<dynamic>?)
              ?.map((e) => UserScreenModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// Address model for create/update
class UserAddress {
  final String? countryIsoCode;
  final String? stateIsoCode;
  final String cityName;
  final String addressLine1;
  final String addressLine2;
  final String postalCode;

  UserAddress({
    this.countryIsoCode,
    this.stateIsoCode,
    required this.cityName,
    required this.addressLine1,
    required this.addressLine2,
    required this.postalCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'countryIsoCode': countryIsoCode,
      'stateIsoCode': stateIsoCode,
      'cityName': cityName,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'postalCode': postalCode,
    };
  }

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      countryIsoCode: json['countryIsoCode'],
      stateIsoCode: json['stateIsoCode'],
      cityName: json['cityName'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'] ?? '',
      postalCode: json['postalCode'] ?? '',
    );
  }
}
