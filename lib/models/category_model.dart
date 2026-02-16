import '../widgets/generic/generic_model.dart';

class CategoryModel implements GenericModel {
  @override
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final int? productCount;
  final int selectionCount;
  @override
  final String createdBy;
  @override
  final String createdAt;
  final String? updatedBy;
  final String? updatedAt;
  final List<CategoryAction> actions;

  CategoryModel ({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    this.productCount,
    this.selectionCount = 0,
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
      'description': description,
      'isActive': isActive,
      if (productCount != null) 'productCount': productCount,
      'selectionCount': selectionCount,
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
      case 'description':
        return description;
      case 'isActive':
        return isActive ? 'Active' : 'Inactive';
      case 'createdBy':
        return createdBy;
      case 'createdAt':
        return createdAt;
      case 'productCount':
        return productCount?.toString() ?? '0';
      case 'selectionCount':
        return selectionCount.toString();
      default:
        return null;
    }
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
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

    // Extract name from creator/updater object (firstName + lastName)
    String extractCreatorName(dynamic value) {
      if (value == null) return '';
      if (value is Map<String, dynamic>) {
        final firstName = value['firstName']?.toString() ?? '';
        final lastName = value['lastName']?.toString() ?? '';
        return '$firstName $lastName'.trim();
      }
      return extractString(value);
    }

    // Extract date from createdInfo/updatedInfo format: "name (date, time)"
    String extractDateFromInfo(dynamic info) {
      if (info == null) return '';
      final str = info.toString();
      final match = RegExp(r'\((.+)\)').firstMatch(str);
      return match?.group(1) ?? '';
    }

    // Resolve createdBy: prefer creator object, fallback to createdBy field, then createdInfo
    final createdBy = extractCreatorName(json['creator']).isNotEmpty
        ? extractCreatorName(json['creator'])
        : extractString(json['createdBy']).isNotEmpty
            ? extractString(json['createdBy'])
            : (json['createdInfo'] != null ? json['createdInfo'].toString().split('(').first.trim() : '');

    // Resolve createdAt: prefer createdAt field, fallback to createdInfo date
    final createdAt = (json['createdAt'] != null && json['createdAt'].toString().isNotEmpty)
        ? json['createdAt'].toString()
        : extractDateFromInfo(json['createdInfo']);

    // Resolve updatedBy: prefer updater object, fallback to updatedBy field, then updatedInfo
    final updatedBy = extractCreatorName(json['updater']).isNotEmpty
        ? extractCreatorName(json['updater'])
        : extractString(json['updatedBy']).isNotEmpty
            ? extractString(json['updatedBy'])
            : (json['updatedInfo'] != null ? json['updatedInfo'].toString().split('(').first.trim() : null);

    // Resolve updatedAt: prefer updatedAt field, fallback to updatedInfo date
    final updatedAt = (json['updatedAt'] != null && json['updatedAt'].toString().isNotEmpty)
        ? json['updatedAt'].toString()
        : (json['updatedInfo'] != null ? extractDateFromInfo(json['updatedInfo']) : null);

    return CategoryModel(
      id: json['id'] ?? extractedId,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] == 'Active' || json['isActive'] == true,
      productCount: json['productCount'],
      selectionCount: json['selectionCount'] is int ? json['selectionCount'] : int.tryParse(json['selectionCount']?.toString() ?? '') ?? 0,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedBy: updatedBy,
      updatedAt: updatedAt,
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => CategoryAction.fromJson(e))
          .toList() ?? [],
    );
  }
}

class CategoryAction {
  final String icon;
  final String type;
  final String? routerLink;
  final String? deleteEndpoint;
  final bool isDisabled;
  final String tooltip;

  CategoryAction({
    required this.icon,
    required this.type,
    this.routerLink,
    this.deleteEndpoint,
    required this.isDisabled,
    required this.tooltip,
  });

  factory CategoryAction.fromJson(Map<String, dynamic> json) {
    return CategoryAction(
      icon: json['icon'] ?? '',
      type: json['type'] ?? '',
      routerLink: json['routerLink'],
      deleteEndpoint: json['deleteEndpoint'],
      isDisabled: json['isDisabled'] ?? false,
      tooltip: json['tooltip'] ?? '',
    );
  }
}

class CategoryResponse {
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final List<CategoryModel> records;

  CategoryResponse({
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.records,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return CategoryResponse(
      total: data['total'] ?? 0,
      page: data['page'] ?? 1,
      take: data['take'] ?? 20,
      totalPages: data['totalPages'] ?? 1,
      records: (data['records'] as List<dynamic>?)
          ?.map((e) => CategoryModel.fromJson(e))
          .toList() ?? [],
    );
  }
}