import '../widgets/generic/generic_model.dart';

class TagModel implements GenericModel {
  @override
  final String id;
  final String name;
  final bool isActive;
  final String createdBy;
  final String createdAt;
  final String? updatedBy;
  final String? updatedAt;
  final List<TagAction> actions;

  TagModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    this.updatedAt,
    required this.actions,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (updatedAt != null) 'updatedAt': updatedAt,
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
      case 'isActive':
        return isActive ? 'Active' : 'Inactive';
      case 'createdBy':
        return createdBy;
      case 'createdAt':
        return createdAt;
      default:
        return null;
    }
  }

  factory TagModel.fromJson(Map<String, dynamic> json) {
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

    return TagModel(
      id: json['id'] ?? extractedId,
      name: json['name'] ?? '',
      isActive: json['isActive'] == 'Active' || json['isActive'] == true,
      createdBy: extractString(json['createdBy']),
      createdAt: json['createdAt'] ?? '',
      updatedBy: extractString(json['updatedBy']),
      updatedAt: json['updatedAt'],
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => TagAction.fromJson(e))
          .toList() ?? [],
    );
  }
}

class TagAction {
  final String icon;
  final String type;
  final String? routerLink;
  final String? deleteEndpoint;
  final bool isDisabled;
  final String tooltip;

  TagAction({
    required this.icon,
    required this.type,
    this.routerLink,
    this.deleteEndpoint,
    required this.isDisabled,
    required this.tooltip,
  });

  factory TagAction.fromJson(Map<String, dynamic> json) {
    return TagAction(
      icon: json['icon'] ?? '',
      type: json['type'] ?? '',
      routerLink: json['routerLink'],
      deleteEndpoint: json['deleteEndpoint'],
      isDisabled: json['isDisabled'] ?? false,
      tooltip: json['tooltip'] ?? '',
    );
  }
}

class TagResponse {
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final List<TagModel> records;

  TagResponse({
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.records,
  });

  factory TagResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return TagResponse(
      total: data['total'] ?? 0,
      page: data['page'] ?? 1,
      take: data['take'] ?? 20,
      totalPages: data['totalPages'] ?? 1,
      records: (data['records'] as List<dynamic>?)
          ?.map((e) => TagModel.fromJson(e))
          .toList() ?? [],
    );
  }
}
