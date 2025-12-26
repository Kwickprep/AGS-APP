import '../widgets/generic/generic_model.dart';

class BrandModel implements GenericModel {
  @override
  final String id;
  final String name;
  final bool isActive;
  @override
  final String createdBy;
  @override
  final String createdAt;
  final List<BrandAction> actions;
  final double? aop;
  final double? discount;

  BrandModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.actions,
    this.aop,
    this.discount,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
      if (aop != null) 'aop': aop,
      if (discount != null) 'discount': discount,
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
      case 'aop':
        return aop != null ? '${aop!.toStringAsFixed(2)}%' : 'N/A';
      case 'discount':
        return discount != null ? '${discount!.toStringAsFixed(2)}%' : 'N/A';
      default:
        return null;
    }
  }

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
      aop: json['aop'] != null ? (json['aop'] as num).toDouble() : null,
      discount: json['discount'] != null ? (json['discount'] as num).toDouble() : null,
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