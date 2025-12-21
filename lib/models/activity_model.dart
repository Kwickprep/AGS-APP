import '../widgets/generic/generic_model.dart';

class ActivityModel implements GenericModel {
  @override
  final String id;
  final String activityType;
  final String company;
  final String inquiry;
  final String user;
  final String source;
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
  final ActivityBody? body; // New field for complete body data

  ActivityModel({
    required this.id,
    required this.activityType,
    required this.company,
    required this.inquiry,
    required this.user,
    required this.source,
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
    this.body,
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
      case 'source':
        return source;
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

    // Parse body if available
    ActivityBody? activityBody;
    if (json['body'] != null) {
      activityBody = ActivityBody.fromJson(json['body']);
    }

    // Helper function to extract string value from either string or object
    String extractString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map<String, dynamic>) {
        return value['name']?.toString() ?? value['id']?.toString() ?? '';
      }
      return value.toString();
    }

    return ActivityModel(
      id: json['id'] ?? extractedId,
      activityType: extractString(json['activityType']),
      company: extractString(json['company']),
      inquiry: extractString(json['inquiry']),
      user: extractString(json['user']),
      source: extractString(json['source']),
      theme: extractString(json['theme']),
      category: extractString(json['category']),
      priceRange: extractString(json['priceRange']),
      product: extractString(json['product']),
      moq: extractString(json['moq']),
      documents: extractString(json['documents']),
      nextScheduleDate: extractString(json['nextScheduleDate']),
      note: extractString(json['note']),
      createdBy: extractString(json['createdBy']),
      createdAt: extractString(json['createdAt']),
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => ActivityAction.fromJson(e))
              .toList() ??
          [],
      body: activityBody,
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
      'source': source,
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

// Activity Body Model for Product Search activities
class ActivityBody {
  final String? note;
  final String? nextScheduleDate;
  final String? nextScheduleNote;
  final bool? scheduledCallCompleted;
  final String? inputText;
  final List<String>? documentIds;
  final String? stage;
  final List<dynamic>? aiSuggestedThemes;
  final Map<String, dynamic>? selectedTheme;
  final List<dynamic>? aiSuggestedCategories;
  final Map<String, dynamic>? selectedCategory;
  final List<dynamic>? availablePriceRanges;
  final Map<String, dynamic>? selectedPriceRange;
  final List<dynamic>? aiSuggestedProducts;
  final Map<String, dynamic>? selectedProduct;
  final String? moq;

  ActivityBody({
    this.note,
    this.nextScheduleDate,
    this.nextScheduleNote,
    this.scheduledCallCompleted,
    this.inputText,
    this.documentIds,
    this.stage,
    this.aiSuggestedThemes,
    this.selectedTheme,
    this.aiSuggestedCategories,
    this.selectedCategory,
    this.availablePriceRanges,
    this.selectedPriceRange,
    this.aiSuggestedProducts,
    this.selectedProduct,
    this.moq,
  });

  factory ActivityBody.fromJson(Map<String, dynamic> json) {
    return ActivityBody(
      note: json['note'],
      nextScheduleDate: json['nextScheduleDate'],
      nextScheduleNote: json['nextScheduleNote'],
      scheduledCallCompleted: json['scheduledCallCompleted'],
      inputText: json['inputText'],
      documentIds: json['documentIds'] != null
          ? List<String>.from(json['documentIds'])
          : null,
      stage: json['stage'],
      aiSuggestedThemes: json['aiSuggestedThemes'],
      selectedTheme: json['selectedTheme'],
      aiSuggestedCategories: json['aiSuggestedCategories'],
      selectedCategory: json['selectedCategory'],
      availablePriceRanges: json['availablePriceRanges'],
      selectedPriceRange: json['selectedPriceRange'],
      aiSuggestedProducts: json['aiSuggestedProducts'],
      selectedProduct: json['selectedProduct'],
      moq: json['moq'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (note != null) data['note'] = note;
    if (nextScheduleDate != null) data['nextScheduleDate'] = nextScheduleDate;
    if (nextScheduleNote != null) data['nextScheduleNote'] = nextScheduleNote;
    if (scheduledCallCompleted != null) data['scheduledCallCompleted'] = scheduledCallCompleted;
    if (inputText != null) data['inputText'] = inputText;
    if (documentIds != null) data['documentIds'] = documentIds;
    if (stage != null) data['stage'] = stage;
    if (aiSuggestedThemes != null) data['aiSuggestedThemes'] = aiSuggestedThemes;
    if (selectedTheme != null) data['selectedTheme'] = selectedTheme;
    if (aiSuggestedCategories != null) data['aiSuggestedCategories'] = aiSuggestedCategories;
    if (selectedCategory != null) data['selectedCategory'] = selectedCategory;
    if (availablePriceRanges != null) data['availablePriceRanges'] = availablePriceRanges;
    if (selectedPriceRange != null) data['selectedPriceRange'] = selectedPriceRange;
    if (aiSuggestedProducts != null) data['aiSuggestedProducts'] = aiSuggestedProducts;
    if (selectedProduct != null) data['selectedProduct'] = selectedProduct;
    if (moq != null) data['moq'] = moq;
    
    return data;
  }
}
