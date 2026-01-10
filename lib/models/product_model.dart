import '../widgets/generic/generic_model.dart';

class ProductModel implements GenericModel {
  @override
  final String id;
  final String name;
  final String image;
  final String price;
  final String priceRange;
  final String category;
  final String brand;
  final String aop;
  final String landed;
  final int tagCount;
  final String description;
  final int themeCount;
  final int priceValue;
  final int priceRangeMin;
  final int priceRangeMax;
  final List<ProductImage> images;
  final BrandObject? brandObject;
  final List<CategoryObject> categories;
  final List<TagObject> tags;
  final List<ThemeObject> themes;
  final List<SimpleTheme> themesSimple;
  final Creator? creator;
  final Creator? updater;
  final String updatedAt;
  final bool isActive;
  @override
  final String createdBy;
  @override
  final String createdAt;
  final List<ProductAction> actions;

  ProductModel({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.priceRange,
    required this.category,
    required this.brand,
    required this.aop,
    required this.landed,
    required this.tagCount,
    required this.description,
    required this.themeCount,
    required this.priceValue,
    required this.priceRangeMin,
    required this.priceRangeMax,
    required this.images,
    this.brandObject,
    required this.categories,
    required this.tags,
    required this.themes,
    required this.themesSimple,
    this.creator,
    this.updater,
    required this.updatedAt,
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
      'image': image,
      'price': price,
      'priceRange': priceRange,
      'category': category,
      'brand': brand,
      'aop': aop,
      'landed': landed,
      'tagCount': tagCount,
      'description': description,
      'themeCount': themeCount,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  @override
  dynamic getFieldValue(String fieldKey) {
    switch (fieldKey) {
      case 'id':
        return id;
      case 'name':
        return name;
      case 'image':
        return image;
      case 'price':
        return price;
      case 'priceRange':
        return priceRange;
      case 'category':
        return category;
      case 'brand':
        return brand;
      case 'aop':
        return aop;
      case 'landed':
        return landed;
      case 'tagCount':
        return tagCount.toString();
      case 'themeCount':
        return themeCount.toString();
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

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: json['price']?.toString() ?? '',
      priceRange: json['priceRange']?.toString() ?? '',
      category: json['category'] ?? '',
      brand: json['brand'] ?? '',
      aop: json['aop']?.toString() ?? '-',
      landed: json['landed']?.toString() ?? '-',
      tagCount: json['tagCount'] ?? 0,
      description: json['description'] ?? '',
      themeCount: json['themeCount'] ?? 0,
      priceValue: json['priceValue'] ?? 0,
      priceRangeMin: json['priceRangeMin'] ?? 0,
      priceRangeMax: json['priceRangeMax'] ?? 0,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => ProductImage.fromJson(e))
              .toList() ??
          [],
      brandObject: json['brandObject'] != null
          ? BrandObject.fromJson(json['brandObject'])
          : null,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => CategoryObject.fromJson(e))
              .toList() ??
          [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => TagObject.fromJson(e))
              .toList() ??
          [],
      themes: (json['themesFull'] as List<dynamic>?)
              ?.map((e) => ThemeObject.fromJson(e))
              .toList() ??
          [],
      themesSimple: (json['themes'] as List<dynamic>?)
              ?.map((e) => SimpleTheme.fromJson(e))
              .toList() ??
          [],
      creator:
          json['creator'] != null ? Creator.fromJson(json['creator']) : null,
      updater:
          json['updater'] != null ? Creator.fromJson(json['updater']) : null,
      updatedAt: json['updatedAt'] ?? '',
      isActive: json['isActive'] == 'Active' || json['isActive'] == true,
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] ?? '',
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => ProductAction.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ProductImage {
  final String id;
  final String fileName;
  final String fileKey;
  final String fileUrl;
  final String mimeType;
  final int size;

  ProductImage({
    required this.id,
    required this.fileName,
    required this.fileKey,
    required this.fileUrl,
    required this.mimeType,
    required this.size,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] ?? '',
      fileName: json['fileName'] ?? '',
      fileKey: json['fileKey'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      mimeType: json['mimeType'] ?? '',
      size: json['size'] ?? 0,
    );
  }
}

class BrandObject {
  final String id;
  final String name;
  final bool isActive;

  BrandObject({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory BrandObject.fromJson(Map<String, dynamic> json) {
    return BrandObject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}

class CategoryObject {
  final String id;
  final String name;
  final String description;
  final bool isActive;

  CategoryObject({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  factory CategoryObject.fromJson(Map<String, dynamic> json) {
    return CategoryObject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}

class TagObject {
  final String id;
  final String name;
  final bool isActive;

  TagObject({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory TagObject.fromJson(Map<String, dynamic> json) {
    return TagObject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}

class SimpleTheme {
  final String name;

  SimpleTheme({
    required this.name,
  });

  factory SimpleTheme.fromJson(Map<String, dynamic> json) {
    return SimpleTheme(
      name: json['name'] ?? '',
    );
  }
}

class ThemeObject {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String productId;
  final String themeId;
  final int relevanceScore;
  final String reason;
  final Theme? theme;

  ThemeObject({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.productId,
    required this.themeId,
    required this.relevanceScore,
    required this.reason,
    this.theme,
  });

  factory ThemeObject.fromJson(Map<String, dynamic> json) {
    return ThemeObject(
      id: json['id'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      productId: json['productId'] ?? '',
      themeId: json['themeId'] ?? '',
      relevanceScore: json['relevanceScore'] ?? 0,
      reason: json['reason'] ?? '',
      theme: json['theme'] != null ? Theme.fromJson(json['theme']) : null,
    );
  }
}

class Theme {
  final String id;
  final String name;
  final String description;
  final bool isActive;

  Theme({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  factory Theme.fromJson(Map<String, dynamic> json) {
    return Theme(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}

class Creator {
  final String id;
  final String firstName;
  final String lastName;
  final String role;

  Creator({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

class ProductAction {
  final String icon;
  final String type;
  final String? routerLink;
  final String? deleteEndpoint;
  final bool isDisabled;
  final String tooltip;

  ProductAction({
    required this.icon,
    required this.type,
    this.routerLink,
    this.deleteEndpoint,
    required this.isDisabled,
    required this.tooltip,
  });

  factory ProductAction.fromJson(Map<String, dynamic> json) {
    return ProductAction(
      icon: json['icon'] ?? '',
      type: json['type'] ?? '',
      routerLink: json['routerLink'],
      deleteEndpoint: json['deleteEndpoint'],
      isDisabled: json['isDisabled'] ?? false,
      tooltip: json['tooltip'] ?? '',
    );
  }
}

class ProductResponse {
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final List<ProductModel> records;

  ProductResponse({
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.records,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return ProductResponse(
      total: data['total'] ?? 0,
      page: data['page'] ?? 1,
      take: data['take'] ?? 20,
      totalPages: data['totalPages'] ?? 1,
      records: (data['records'] as List<dynamic>?)
              ?.map((e) => ProductModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
