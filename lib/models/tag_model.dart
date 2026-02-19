import '../widgets/generic/generic_model.dart';

class TagModel implements GenericModel {
  @override
  final String id;
  final String name;
  final bool isActive;
  final int productCount;
  final String createdBy;
  final String createdAt;
  final String? updatedBy;
  final String? updatedAt;
  final List<TagAction> actions;

  TagModel({
    required this.id,
    required this.name,
    required this.isActive,
    this.productCount = 0,
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
      'productCount': productCount,
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
      case 'productCount':
        return productCount.toString();
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

    // Helper to extract user name from creator/updater object, fallback to raw string
    String extractUserName(dynamic obj, dynamic fallback) {
      if (obj is Map<String, dynamic>) {
        final first = obj['firstName']?.toString() ?? '';
        final last = obj['lastName']?.toString() ?? '';
        final name = '$first $last'.trim();
        if (name.isNotEmpty) return name;
      }
      if (fallback == null) return '';
      if (fallback is String) return fallback;
      if (fallback is Map<String, dynamic>) {
        return fallback['name']?.toString() ?? fallback['id']?.toString() ?? '';
      }
      return fallback.toString();
    }

    // Extract name from creator/updater object (firstName + lastName)

    String extractString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map<String, dynamic>) {
        return value['name']?.toString() ?? value['id']?.toString() ?? '';
      }
      return value.toString();
    }

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

    return TagModel(
      id: json['id'] ?? extractedId,
      name: json['name'] ?? '',
      isActive: json['isActive'] == 'Active' || json['isActive'] == true,
      productCount: json['productCount'] is int ? json['productCount'] : int.tryParse(json['productCount']?.toString() ?? '') ?? 0,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedBy: updatedBy,
      updatedAt: updatedAt,
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
