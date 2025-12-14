import '../widgets/generic/generic_model.dart';

class ActivityModel implements GenericModel {
  @override
  final String id;
  final String activityType;
  final String company;
  final String inquiry;
  final String user;
  final String theme;
  final String category;
  final String priceRange;
  final String product;
  final String moq;
  final String documents;
  final String nextScheduleDate;
  final String note;
  @override
  final String createdBy;
  @override
  final String createdAt;
  final List<ActivityAction> actions;

  ActivityModel({
    required this.id,
    required this.activityType,
    required this.company,
    required this.inquiry,
    required this.user,
    required this.theme,
    required this.category,
    required this.priceRange,
    required this.product,
    required this.moq,
    required this.documents,
    required this.nextScheduleDate,
    required this.note,
    required this.createdBy,
    required this.createdAt,
    required this.actions,
  });

  @override
  dynamic getFieldValue(String fieldKey) {
    switch (fieldKey) {
      case 'id':
        return id;
      case 'activityType':
        return activityType;
      case 'company':
        return company;
      case 'inquiry':
        return inquiry;
      case 'user':
        return user;
      case 'theme':
        return theme;
      case 'category':
        return category;
      case 'priceRange':
        return priceRange;
      case 'product':
        return product;
      case 'moq':
        return moq;
      case 'documents':
        return documents;
      case 'nextScheduleDate':
        return nextScheduleDate;
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

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
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

    return ActivityModel(
      id: json['id'] ?? extractedId,
      activityType: json['activityType'] ?? '',
      company: json['company'] ?? '',
      inquiry: json['inquiry'] ?? '',
      user: json['user'] ?? '',
      theme: json['theme'] ?? '',
      category: json['category'] ?? '',
      priceRange: json['priceRange'] ?? '',
      product: json['product'] ?? '',
      moq: json['moq'] ?? '',
      documents: json['documents'] ?? '',
      nextScheduleDate: json['nextScheduleDate'] ?? '',
      note: json['note'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] ?? '',
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => ActivityAction.fromJson(e))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityType': activityType,
      'company': company,
      'inquiry': inquiry,
      'user': user,
      'theme': theme,
      'category': category,
      'priceRange': priceRange,
      'product': product,
      'moq': moq,
      'documents': documents,
      'nextScheduleDate': nextScheduleDate,
      'note': note,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }
}

class ActivityAction {
  final String icon;
  final String type;
  final String? routerLink;
  final String? deleteEndpoint;
  final bool isDisabled;
  final String tooltip;

  ActivityAction({
    required this.icon,
    required this.type,
    this.routerLink,
    this.deleteEndpoint,
    required this.isDisabled,
    required this.tooltip,
  });

  factory ActivityAction.fromJson(Map<String, dynamic> json) {
    return ActivityAction(
      icon: json['icon'] ?? '',
      type: json['type'] ?? '',
      routerLink: json['routerLink'],
      deleteEndpoint: json['deleteEndpoint'],
      isDisabled: json['isDisabled'] ?? false,
      tooltip: json['tooltip'] ?? '',
    );
  }
}

class ActivityResponse {
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final List<ActivityModel> records;

  ActivityResponse({
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.records,
  });

  factory ActivityResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return ActivityResponse(
      total: data['total'] ?? 0,
      page: data['page'] ?? 1,
      take: data['take'] ?? 20,
      totalPages: data['totalPages'] ?? 1,
      records: (data['records'] as List<dynamic>?)
              ?.map((e) => ActivityModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
