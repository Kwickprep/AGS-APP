import '../widgets/generic/generic_model.dart';

class InquiryModel implements GenericModel {
  @override
  final String id;
  final String name;
  final String company;
  final String contactUser;
  final String status;
  final String note;
  @override
  final String createdBy;
  @override
  final String createdAt;
  final String? updatedBy;
  final String? updatedAt;
  final String createdInfo;
  final String? updatedInfo;
  final List<InquiryAction> actions;

  InquiryModel({
    required this.id,
    required this.name,
    required this.company,
    required this.contactUser,
    required this.status,
    required this.note,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.createdInfo = '',
    this.updatedInfo,
    required this.actions,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'contactUser': contactUser,
      'status': status,
      'note': note,
      'createdBy': createdBy,
      'createdAt': createdAt,
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (createdInfo.isNotEmpty) 'createdInfo': createdInfo,
      if (updatedInfo != null) 'updatedInfo': updatedInfo,
      'actions': actions.map((a) => {
        'icon': a.icon,
        'type': a.type,
        'routerLink': a.routerLink,
        'deleteEndpoint': a.deleteEndpoint,
        'isDisabled': a.isDisabled,
        'tooltip': a.tooltip,
      }).toList(),
    };
  }

  @override
  dynamic getFieldValue(String fieldKey) {
    switch (fieldKey) {
      case 'id':
        return id;
      case 'name':
        return name;
      case 'company':
        return company;
      case 'contactUser':
        return contactUser;
      case 'status':
        return status;
      case 'note':
        return note;
      case 'createdBy':
        return createdBy;
      case 'createdAt':
        return createdAt;
      default:
        return null;
    }
  }

  factory InquiryModel.fromJson(Map<String, dynamic> json) {
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

    // Helper function to extract string value from either string or object
    String extractString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map<String, dynamic>) {
        return value['name']?.toString() ?? value['fullName']?.toString() ?? value['id']?.toString() ?? '';
      }
      return value.toString();
    }

    return InquiryModel(
      id: json['id'] ?? extractedId,
      name: json['name'] ?? '',
      company: extractString(json['company']),
      contactUser: extractString(json['contactUser']),
      status: json['status'] ?? '',
      note: json['note'] ?? '',
      createdBy: extractString(json['createdBy']),
      createdAt: json['createdAt'] ?? '',
      updatedBy: extractString(json['updatedBy']),
      updatedAt: json['updatedAt'],
      createdInfo: json['createdInfo'] ?? '',
      updatedInfo: json['updatedInfo'],
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => InquiryAction.fromJson(e))
          .toList() ?? [],
    );
  }
}

class InquiryAction {
  final String icon;
  final String type;
  final String? routerLink;
  final String? deleteEndpoint;
  final bool isDisabled;
  final String tooltip;

  InquiryAction({
    required this.icon,
    required this.type,
    this.routerLink,
    this.deleteEndpoint,
    required this.isDisabled,
    required this.tooltip,
  });

  factory InquiryAction.fromJson(Map<String, dynamic> json) {
    return InquiryAction(
      icon: json['icon'] ?? '',
      type: json['type'] ?? '',
      routerLink: json['routerLink'],
      deleteEndpoint: json['deleteEndpoint'],
      isDisabled: json['isDisabled'] ?? false,
      tooltip: json['tooltip'] ?? '',
    );
  }
}

class InquiryResponse {
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final List<InquiryModel> records;

  InquiryResponse({
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.records,
  });

  factory InquiryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return InquiryResponse(
      total: data['total'] ?? 0,
      page: data['page'] ?? 1,
      take: data['take'] ?? 20,
      totalPages: data['totalPages'] ?? 1,
      records: (data['records'] as List<dynamic>?)
          ?.map((e) => InquiryModel.fromJson(e))
          .toList() ?? [],
    );
  }
}
