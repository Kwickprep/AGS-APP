class ThemeModel {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final String createdBy;
  final String createdAt;
  final List<ThemeAction> actions;

  ThemeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.actions,
  });

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
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

    return ThemeModel(
      id: json['id'] ?? extractedId,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] == 'Active' || json['isActive'] == true,
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] ?? '',
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => ThemeAction.fromJson(e))
          .toList() ?? [],
    );
  }
}

class ThemeAction {
  final String icon;
  final String type;
  final String? routerLink;
  final String? deleteEndpoint;
  final bool isDisabled;
  final String tooltip;

  ThemeAction({
    required this.icon,
    required this.type,
    this.routerLink,
    this.deleteEndpoint,
    required this.isDisabled,
    required this.tooltip,
  });

  factory ThemeAction.fromJson(Map<String, dynamic> json) {
    return ThemeAction(
      icon: json['icon'] ?? '',
      type: json['type'] ?? '',
      routerLink: json['routerLink'],
      deleteEndpoint: json['deleteEndpoint'],
      isDisabled: json['isDisabled'] ?? false,
      tooltip: json['tooltip'] ?? '',
    );
  }
}

class ThemeResponse {
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final List<ThemeModel> records;

  ThemeResponse({
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.records,
  });

  factory ThemeResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return ThemeResponse(
      total: data['total'] ?? 0,
      page: data['page'] ?? 1,
      take: data['take'] ?? 20,
      totalPages: data['totalPages'] ?? 1,
      records: (data['records'] as List<dynamic>?)
          ?.map((e) => ThemeModel.fromJson(e))
          .toList() ?? [],
    );
  }
}