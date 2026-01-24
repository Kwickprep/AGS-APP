class UserProductSearchModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final double? price;
  final String? category;
  final Map<String, dynamic>? additionalData;

  UserProductSearchModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.price,
    this.category,
    this.additionalData,
  });

  factory UserProductSearchModel.fromJson(Map<String, dynamic> json) {
    return UserProductSearchModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'] ?? json['image_url'] ?? json['image'],
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      category: json['category'],
      additionalData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'category': category,
    };
  }
}

/// Chat message model for the conversation
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? imageUrls;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.imageUrls,
  });
}

/// AI Suggested Theme model
class AISuggestedTheme {
  final String id;
  final String name;
  final String? reason;
  final String? icon;

  AISuggestedTheme({
    required this.id,
    required this.name,
    this.reason,
    this.icon,
  });

  factory AISuggestedTheme.fromJson(Map<String, dynamic> json) {
    return AISuggestedTheme(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      reason: json['reason'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'reason': reason,
      'icon': icon,
    };
  }
}

/// AI Suggested Category model
class AISuggestedCategory {
  final String id;
  final String name;
  final String? description;
  final String? icon;

  AISuggestedCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
  });

  factory AISuggestedCategory.fromJson(Map<String, dynamic> json) {
    return AISuggestedCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
    };
  }
}

class UserProductSearchResponse {
  final bool success;
  final String? message;
  final String? activityId;
  final List<UserProductSearchModel> products;
  final List<AISuggestedTheme> aiSuggestedThemes;
  final List<AISuggestedCategory> aiSuggestedCategories;
  final String? stage;
  final Map<String, dynamic>? metadata;

  UserProductSearchResponse({
    required this.success,
    this.message,
    this.activityId,
    required this.products,
    this.aiSuggestedThemes = const [],
    this.aiSuggestedCategories = const [],
    this.stage,
    this.metadata,
  });

  factory UserProductSearchResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    List<UserProductSearchModel> productList = [];
    List<AISuggestedTheme> themeList = [];
    List<AISuggestedCategory> categoryList = [];
    String? activityId;
    String? stage;

    if (data != null) {
      // Get activity ID
      activityId = data['id']?.toString();

      // Get body data
      final body = data['body'];
      if (body != null) {
        stage = body['stage'];

        // Parse AI suggested themes
        final themes = body['aiSuggestedThemes'];
        if (themes != null && themes is List) {
          themeList = themes
              .map((e) => AISuggestedTheme.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        // Parse AI suggested categories
        final categories = body['aiSuggestedCategories'];
        if (categories != null && categories is List) {
          categoryList = categories
              .map((e) => AISuggestedCategory.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      // Parse products if available
      if (data is List) {
        productList =
            data.map((e) => UserProductSearchModel.fromJson(e)).toList();
      } else if (data is Map<String, dynamic>) {
        final records = data['records'] ?? data['products'] ?? data['items'];
        if (records is List) {
          productList = records
              .map((e) => UserProductSearchModel.fromJson(e))
              .toList();
        }
      }
    }

    return UserProductSearchResponse(
      success: json['success'] ?? true,
      message: json['message'],
      activityId: activityId,
      products: productList,
      aiSuggestedThemes: themeList,
      aiSuggestedCategories: categoryList,
      stage: stage,
      metadata: json['metadata'],
    );
  }
}
