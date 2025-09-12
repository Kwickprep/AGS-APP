class BrandModel {
  final String id;
  final String name;
  final bool isActive;
  final String createdBy;
  final String createdAt;
  final List<BrandAction> actions;

  BrandModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.actions,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
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

    return BrandModel(
      id: json['id'] ?? extractedId,
      name: json['name'] ?? '',
      isActive: json['isActive'] == 'Active' || json['isActive'] == true,
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] ?? '',
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => BrandAction.fromJson(e))
          .toList() ?? [],
    );
  }
}

class BrandAction {
  final String icon;
  final String type;
  final String? routerLink;
  final String? deleteEndpoint;
  final bool isDisabled;
  final String tooltip;

  BrandAction({
    required this.icon,
    required this.type,
    this.routerLink,
    this.deleteEndpoint,
    required this.isDisabled,
    required this.tooltip,
  });

  factory BrandAction.fromJson(Map<String, dynamic> json) {
    return BrandAction(
      icon: json['icon'] ?? '',
      type: json['type'] ?? '',
      routerLink: json['routerLink'],
      deleteEndpoint: json['deleteEndpoint'],
      isDisabled: json['isDisabled'] ?? false,
      tooltip: json['tooltip'] ?? '',
    );
  }
}

class BrandResponse {
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final List<BrandModel> records;

  BrandResponse({
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.records,
  });

  factory BrandResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return BrandResponse(
      total: data['total'] ?? 0,
      page: data['page'] ?? 1,
      take: data['take'] ?? 20,
      totalPages: data['totalPages'] ?? 1,
      records: (data['records'] as List<dynamic>?)
          ?.map((e) => BrandModel.fromJson(e))
          .toList() ?? [],
    );
  }
}