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
  final String? productImageFileId;
  final String aop;
  final String moq;
  final String documents;
  final String nextScheduleDate;
  final String note;
  @override
  final String createdBy;
  @override
  final String createdAt;
  final String? updatedBy;
  final String? updatedAt;
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
    this.productImageFileId,
    required this.aop,
    required this.moq,
    required this.documents,
    required this.nextScheduleDate,
    required this.note,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    this.updatedAt,
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
      case 'aop':
        return aop;
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
    // Extract ID: try direct fields first, then from actions
    print('ActivityModel.fromJson keys: ${json.keys.toList()}');
    print('ActivityModel.fromJson id: ${json['id']}, _id: ${json['_id']}');
    String id = (json['id'] ?? json['_id'] ?? '').toString();

    if (id.isEmpty && json['actions'] != null) {
      final actions = json['actions'] as List;
      for (final action in actions) {
        if (action is Map<String, dynamic>) {
          // Try routerLink: e.g. "/activities/edit/abc123"
          final routerLink = action['routerLink'] as String?;
          if (routerLink != null && routerLink.isNotEmpty) {
            final parts = routerLink.split('/');
            if (parts.length > 2) {
              id = parts.last;
              break;
            }
          }
          // Try deleteEndpoint: e.g. "/api/activities/abc123"
          final deleteEndpoint = action['deleteEndpoint'] as String?;
          if (deleteEndpoint != null && deleteEndpoint.isNotEmpty) {
            final parts = deleteEndpoint.split('/');
            if (parts.isNotEmpty) {
              id = parts.last;
              break;
            }
          }
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

    return ActivityModel(
      id: id,
      activityType: extractString(json['activityType']),
      company: extractString(json['company']),
      inquiry: extractString(json['inquiry']),
      user: extractString(json['user']),
      source: extractString(json['source']),
      theme: extractString(json['theme']),
      category: extractString(json['category']),
      priceRange: extractString(json['priceRange']),
      product: extractString(json['product']),
      productImageFileId: json['productImageFileId'] as String?
          ?? _extractImageFileId(json['body']),
      aop: extractString(json['aop']),
      moq: extractString(json['moq']),
      documents: extractString(json['documents']),
      nextScheduleDate: extractString(json['nextScheduleDate']),
      note: extractString(json['note']),
      createdBy: extractUserName(json['creator'], json['createdBy']),
      createdAt: extractString(json['createdAt']),
      updatedBy: json['updatedBy'],
      updatedAt: json['updatedAt'],
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => ActivityAction.fromJson(e))
              .toList() ??
          [],
      body: activityBody,
    );
  }

  /// Extract product image file ID from body data.
  /// Tries: selectedProduct.images[0].id → aiSuggestedProducts match by id
  static String? _extractImageFileId(dynamic body) {
    if (body == null || body is! Map<String, dynamic>) return null;
    final selectedProduct = body['selectedProduct'];
    if (selectedProduct == null || selectedProduct is! Map<String, dynamic>) return null;

    // Try selectedProduct.images first (for new activities that include images)
    final images = selectedProduct['images'];
    if (images is List && images.isNotEmpty) {
      final firstImage = images[0];
      if (firstImage is Map<String, dynamic>) {
        final id = firstImage['id'] as String?;
        if (id != null && id.isNotEmpty) return id;
      }
    }

    // Fallback: find this product in aiSuggestedProducts by ID
    final productId = selectedProduct['id'];
    if (productId != null) {
      final aiProducts = body['aiSuggestedProducts'];
      if (aiProducts is List) {
        for (final p in aiProducts) {
          if (p is Map<String, dynamic> && p['id']?.toString() == productId.toString()) {
            final pImages = p['images'];
            if (pImages is List && pImages.isNotEmpty) {
              final firstImg = pImages[0];
              if (firstImg is Map<String, dynamic>) {
                final id = firstImg['id'] as String?;
                if (id != null && id.isNotEmpty) return id;
              }
            }
          }
        }
      }
    }

    return null;
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
      'aop': aop,
      'moq': moq,
      'documents': documents,
      'nextScheduleDate': nextScheduleDate,
      'note': note,
      'createdBy': createdBy,
      'createdAt': createdAt,
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (updatedAt != null) 'updatedAt': updatedAt,
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
