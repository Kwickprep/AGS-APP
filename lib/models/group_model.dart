import '../widgets/generic/generic_model.dart';

class GroupModel implements GenericModel {
  @override
  final String id;
  final String name;
  final String users;
  final String note;
  final bool isActive;
  @override
  final String createdBy;
  @override
  final String createdAt;
  final List<GroupAction> actions;

  GroupModel({
    required this.id,
    required this.name,
    required this.users,
    required this.note,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.actions,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'users': users,
      'note': note,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
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
      case 'users':
        return users;
      case 'note':
        return note;
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

  factory GroupModel.fromJson(Map<String, dynamic> json) {
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

    return GroupModel(
      id: json['id']?.toString() ?? extractedId,
      name: json['name']?.toString() ?? '',
      users: json['users']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      isActive: json['isActive'] == 'Active' || json['isActive'] == true,
      createdBy: json['createdBy']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => GroupAction.fromJson(e))
          .toList() ?? [],
    );
  }
}

class GroupAction {
  final String icon;
  final String type;
  final String? routerLink;
  final String? deleteEndpoint;
  final bool isDisabled;
  final String tooltip;

  GroupAction({
    required this.icon,
    required this.type,
    this.routerLink,
    this.deleteEndpoint,
    required this.isDisabled,
    required this.tooltip,
  });

  factory GroupAction.fromJson(Map<String, dynamic> json) {
    return GroupAction(
      icon: json['icon']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      routerLink: json['routerLink']?.toString(),
      deleteEndpoint: json['deleteEndpoint']?.toString(),
      isDisabled: json['isDisabled'] == true || json['isDisabled'] == 'true',
      tooltip: json['tooltip']?.toString() ?? '',
    );
  }
}

class GroupResponse {
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final List<GroupModel> records;

  GroupResponse({
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.records,
  });

  factory GroupResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return GroupResponse(
      total: data['total'] ?? 0,
      page: data['page'] ?? 1,
      take: data['take'] ?? 20,
      totalPages: data['totalPages'] ?? 1,
      records: (data['records'] as List<dynamic>?)
          ?.map((e) => GroupModel.fromJson(e))
          .toList() ?? [],
    );
  }
}
