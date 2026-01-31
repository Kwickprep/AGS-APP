class UserProductSearchModel {
  final String id;
  final String name;
  final String? description;
  final String? aiGeneratedDescription;
  final String? imageUrl;
  final List<ProductImage> images;
  final String? reason;
  final List<String> conceptAlignment;
  final ProductBrand? brand;
  final List<ProductThemeRef> themes;
  final List<ProductTagRef> tags;
  final Map<String, dynamic>? additionalData;

  UserProductSearchModel({
    required this.id,
    required this.name,
    this.description,
    this.aiGeneratedDescription,
    this.imageUrl,
    this.images = const [],
    this.reason,
    this.conceptAlignment = const [],
    this.brand,
    this.themes = const [],
    this.tags = const [],
    this.additionalData,
  });

  factory UserProductSearchModel.fromJson(Map<String, dynamic> json) {
    return UserProductSearchModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      aiGeneratedDescription: json['aiGeneratedDescription'],
      imageUrl: json['imageUrl'] ?? json['image_url'],
      images: (json['images'] as List?)
              ?.map((e) => ProductImage.fromJson(e))
              .toList() ??
          [],
      reason: json['reason'],
      conceptAlignment: (json['conceptAlignment'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      brand: json['brand'] != null ? ProductBrand.fromJson(json['brand']) : null,
      themes: (json['themes'] as List?)
              ?.map((e) => ProductThemeRef.fromJson(e))
              .toList() ??
          [],
      tags: (json['tags'] as List?)
              ?.map((e) => ProductTagRef.fromJson(e))
              .toList() ??
          [],
      additionalData: json,
    );
  }
}

class ProductImage {
  final String id;
  final String fileUrl;

  ProductImage({required this.id, required this.fileUrl});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id']?.toString() ?? '',
      fileUrl: json['fileUrl'] ?? '',
    );
  }
}

class ProductBrand {
  final String id;
  final String name;

  ProductBrand({required this.id, required this.name});

  factory ProductBrand.fromJson(Map<String, dynamic> json) {
    return ProductBrand(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}

class ProductThemeRef {
  final String id;
  final String name;
  final int? relevanceScore;

  ProductThemeRef({required this.id, required this.name, this.relevanceScore});

  factory ProductThemeRef.fromJson(Map<String, dynamic> json) {
    return ProductThemeRef(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      relevanceScore: json['relevanceScore'],
    );
  }
}

class ProductTagRef {
  final String id;
  final String name;

  ProductTagRef({required this.id, required this.name});

  factory ProductTagRef.fromJson(Map<String, dynamic> json) {
    return ProductTagRef(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
    );
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

/// Price Range model
class PriceRange {
  final String label;
  final int min;
  final int max;

  PriceRange({required this.label, required this.min, required this.max});

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      label: json['label'] ?? '',
      min: json['min'] ?? 0,
      max: json['max'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'label': label, 'min': min, 'max': max};
  }
}

/// MOQ Range model
class MoqRange {
  final String label;
  final String value;

  MoqRange({required this.label, required this.value});

  static List<MoqRange> get options => [
        MoqRange(label: '1 - 100 (Small)', value: '1-100'),
        MoqRange(label: '101 - 1,000 (Medium)', value: '101-1000'),
        MoqRange(label: '1,001 - 3,000 (Large)', value: '1001-3000'),
        MoqRange(label: '3,001 - 5,000 (Bulk)', value: '3001-5000'),
        MoqRange(label: '5,001 - 10,000 (Very Large)', value: '5001-10000'),
        MoqRange(label: 'Above 10,000', value: '10001+'),
      ];
}

class UserProductSearchResponse {
  final bool success;
  final String? message;
  final String? activityId;
  final List<UserProductSearchModel> products;
  final List<AISuggestedTheme> aiSuggestedThemes;
  final List<PriceRange> availablePriceRanges;
  final String? stage;
  final Map<String, dynamic>? metadata;

  UserProductSearchResponse({
    required this.success,
    this.message,
    this.activityId,
    required this.products,
    this.aiSuggestedThemes = const [],
    this.availablePriceRanges = const [],
    this.stage,
    this.metadata,
  });

  factory UserProductSearchResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    List<UserProductSearchModel> productList = [];
    List<AISuggestedTheme> themeList = [];
    List<PriceRange> priceRangeList = [];
    String? activityId;
    String? stage;

    if (data != null) {
      activityId = data['id']?.toString();

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

        // Parse available price ranges
        final priceRanges = body['availablePriceRanges'];
        if (priceRanges != null && priceRanges is List) {
          priceRangeList = priceRanges
              .map((e) => PriceRange.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        // Parse AI suggested products
        final aiProducts = body['aiSuggestedProducts'];
        if (aiProducts != null && aiProducts is List) {
          productList = aiProducts
              .map((e) => UserProductSearchModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      // Fallback product parsing
      if (productList.isEmpty) {
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
    }

    return UserProductSearchResponse(
      success: json['success'] ?? true,
      message: json['message'],
      activityId: activityId,
      products: productList,
      aiSuggestedThemes: themeList,
      availablePriceRanges: priceRangeList,
      stage: stage,
      metadata: json['metadata'],
    );
  }
}
