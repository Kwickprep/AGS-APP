import 'dart:convert';

class ProductSearchResponseModel {
  final int status;
  final bool success;
  final String message;
  final ProductSearchData? data;

  ProductSearchResponseModel({
    required this.status,
    required this.success,
    required this.message,
    this.data,
  });

  factory ProductSearchResponseModel.fromJson(Map<String, dynamic> json) {
    return ProductSearchResponseModel(
      status: json['status'] ?? 200,
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? ProductSearchData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }

  // Helper method to get the body directly
  ProductSearchBody? get body => data?.record?.body;

  // Helper to print JSON for debugging
  String toJsonString() {
    return jsonEncode(toJson());
  }
}

class ProductSearchData {
  final ProductSearchRecord? record;

  ProductSearchData({this.record});

  factory ProductSearchData.fromJson(Map<String, dynamic> json) {
    return ProductSearchData(
      record: json['record'] != null
          ? ProductSearchRecord.fromJson(json['record'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'record': record?.toJson(),
    };
  }
}

class ProductSearchRecord {
  final ProductSearchBody? body;
  final String? id;
  final String? createdBy;
  final String? updatedBy;
  final String? createdAt;
  final String? updatedAt;
  final String? userId;
  final String? companyId;
  final String? inquiryId;
  final String? activityTypeId;
  final String? source;

  ProductSearchRecord({
    this.body,
    this.id,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.companyId,
    this.inquiryId,
    this.activityTypeId,
    this.source,
  });

  factory ProductSearchRecord.fromJson(Map<String, dynamic> json) {
    return ProductSearchRecord(
      body: json['body'] != null
          ? ProductSearchBody.fromJson(json['body'])
          : null,
      id: json['id'],
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      userId: json['userId'],
      companyId: json['companyId'],
      inquiryId: json['inquiryId'],
      activityTypeId: json['activityTypeId'],
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'body': body?.toJson(),
      'id': id,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userId': userId,
      'companyId': companyId,
      'inquiryId': inquiryId,
      'activityTypeId': activityTypeId,
      'source': source,
    };
  }
}

class ProductSearchBody {
  final String? inputText;
  final List<String>? documentIds;
  final String? stage;
  final List<Map<String, dynamic>>? aiSuggestedThemes;
  final Map<String, dynamic>? selectedTheme;
  final List<Map<String, dynamic>>? aiSuggestedCategories;
  final Map<String, dynamic>? selectedCategory;
  final List<Map<String, dynamic>>? availablePriceRanges;
  final Map<String, dynamic>? selectedPriceRange;
  final List<Map<String, dynamic>>? aiSuggestedProducts;
  final Map<String, dynamic>? selectedProduct;
  final String? moq;

  ProductSearchBody({
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

  factory ProductSearchBody.fromJson(Map<String, dynamic> json) {
    return ProductSearchBody(
      inputText: json['inputText'],
      documentIds: json['documentIds'] != null
          ? List<String>.from(json['documentIds'])
          : null,
      stage: json['stage'],
      aiSuggestedThemes: json['aiSuggestedThemes'] != null
          ? List<Map<String, dynamic>>.from(
              json['aiSuggestedThemes'].map((x) => Map<String, dynamic>.from(x)))
          : null,
      selectedTheme: json['selectedTheme'] != null
          ? Map<String, dynamic>.from(json['selectedTheme'])
          : null,
      aiSuggestedCategories: json['aiSuggestedCategories'] != null
          ? List<Map<String, dynamic>>.from(
              json['aiSuggestedCategories'].map((x) => Map<String, dynamic>.from(x)))
          : null,
      selectedCategory: json['selectedCategory'] != null
          ? Map<String, dynamic>.from(json['selectedCategory'])
          : null,
      availablePriceRanges: json['availablePriceRanges'] != null
          ? List<Map<String, dynamic>>.from(
              json['availablePriceRanges'].map((x) => Map<String, dynamic>.from(x)))
          : null,
      selectedPriceRange: json['selectedPriceRange'] != null
          ? Map<String, dynamic>.from(json['selectedPriceRange'])
          : null,
      aiSuggestedProducts: json['aiSuggestedProducts'] != null
          ? List<Map<String, dynamic>>.from(
              json['aiSuggestedProducts'].map((x) => Map<String, dynamic>.from(x)))
          : null,
      selectedProduct: json['selectedProduct'] != null
          ? Map<String, dynamic>.from(json['selectedProduct'])
          : null,
      moq: json['moq'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inputText': inputText,
      'documentIds': documentIds,
      'stage': stage,
      'aiSuggestedThemes': aiSuggestedThemes,
      'selectedTheme': selectedTheme,
      'aiSuggestedCategories': aiSuggestedCategories,
      'selectedCategory': selectedCategory,
      'availablePriceRanges': availablePriceRanges,
      'selectedPriceRange': selectedPriceRange,
      'aiSuggestedProducts': aiSuggestedProducts,
      'selectedProduct': selectedProduct,
      'moq': moq,
    };
  }
}
