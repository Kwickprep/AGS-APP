import '../widgets/generic/generic_model.dart';

class ThemeModel implements GenericModel {
  @override
  final String id;
  final String name;
  final String description;
  final int productCount;
  final bool isActive;
  final bool isActiveRaw;
  @override
  final String createdBy;
  @override
  final String createdAt;
  final String updatedAt;
  final User? creator;
  final User? updater;
  final List<Product> products;
  final List<ThemeAction> actions;

  ThemeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.productCount,
    required this.isActive,
    required this.isActiveRaw,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.creator,
    this.updater,
    required this.products,
    required this.actions,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'productCount': productCount,
      'isActive': isActive,
      'isActiveRaw': isActiveRaw,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'creator': creator?.toJson(),
      'updater': updater?.toJson(),
      'products': products.map((p) => p.toJson()).toList(),
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }

  @override
  dynamic getFieldValue(String fieldKey) {
    switch (fieldKey) {
      case 'id':
        return id;
      case 'name':
        return name;
      case 'description':
        return description;
      case 'productCount':
        return productCount.toString();
      case 'isActive':
        return isActive ? 'Active' : 'Inactive';
      case 'createdBy':
        return createdBy;
      case 'createdAt':
        return createdAt;
      case 'updatedAt':
        return updatedAt;
      default:
        return null;
    }
  }

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
      productCount: json['productCount'] ?? 0,
      isActive: json['isActive'] == 'Active' || json['isActive'] == true,
      isActiveRaw: json['isActiveRaw'] ?? (json['isActive'] == 'Active' || json['isActive'] == true),
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      creator: json['creator'] != null ? User.fromJson(json['creator']) : null,
      updater: json['updater'] != null ? User.fromJson(json['updater']) : null,
      products: (json['products'] as List<dynamic>?)
          ?.map((e) => Product.fromJson(e))
          .toList() ?? [],
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => ThemeAction.fromJson(e))
          .toList() ?? [],
    );
  }
}

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String role;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final bool isActive;
  final String image;
  final int relevanceScore;
  final String? reason;
  final List<OtherTheme> otherThemes;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.isActive,
    required this.image,
    required this.relevanceScore,
    this.reason,
    required this.otherThemes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'isActive': isActive,
      'image': image,
      'relevanceScore': relevanceScore,
      'reason': reason,
      'otherThemes': otherThemes.map((t) => t.toJson()).toList(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? false,
      image: json['image'] ?? '',
      relevanceScore: json['relevanceScore'] ?? 0,
      reason: json['reason'],
      otherThemes: (json['otherThemes'] as List<dynamic>?)
          ?.map((e) => OtherTheme.fromJson(e))
          .toList() ?? [],
    );
  }
}

class OtherTheme {
  final String id;
  final String name;
  final int relevanceScore;
  final String? reason;
  final String description;

  OtherTheme({
    required this.id,
    required this.name,
    required this.relevanceScore,
    this.reason,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relevanceScore': relevanceScore,
      'reason': reason,
      'description': description,
    };
  }

  factory OtherTheme.fromJson(Map<String, dynamic> json) {
    return OtherTheme(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      relevanceScore: json['relevanceScore'] ?? 0,
      reason: json['reason'],
      description: json['description'] ?? '',
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

  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'type': type,
      'routerLink': routerLink,
      'deleteEndpoint': deleteEndpoint,
      'isDisabled': isDisabled,
      'tooltip': tooltip,
    };
  }

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
  final PageLayoutContext? context;

  ThemeResponse({
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.records,
    this.context,
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
      context: data['context'] != null
          ? PageLayoutContext.fromJson(data['context'])
          : null,
    );
  }
}

class PageLayoutContext {
  final PageLayout pageLayout;

  PageLayoutContext({required this.pageLayout});

  factory PageLayoutContext.fromJson(Map<String, dynamic> json) {
    return PageLayoutContext(
      pageLayout: PageLayout.fromJson(json['pageLayout'] ?? {}),
    );
  }
}

class PageLayout {
  final String type;
  final PageHeader header;
  final PageBody body;

  PageLayout({
    required this.type,
    required this.header,
    required this.body,
  });

  factory PageLayout.fromJson(Map<String, dynamic> json) {
    return PageLayout(
      type: json['type'] ?? '',
      header: PageHeader.fromJson(json['header'] ?? {}),
      body: PageBody.fromJson(json['body'] ?? {}),
    );
  }
}

class PageHeader {
  final bool isTitle;
  final String title;
  final bool isBack;
  final bool isCreate;
  final String? createButtonLabel;
  final String? createButtonIcon;
  final List<String>? createButtonLink;

  PageHeader({
    required this.isTitle,
    required this.title,
    required this.isBack,
    required this.isCreate,
    this.createButtonLabel,
    this.createButtonIcon,
    this.createButtonLink,
  });

  factory PageHeader.fromJson(Map<String, dynamic> json) {
    return PageHeader(
      isTitle: json['isTitle'] ?? false,
      title: json['title'] ?? '',
      isBack: json['isBack'] ?? false,
      isCreate: json['isCreate'] ?? false,
      createButtonLabel: json['createButtonLabel'],
      createButtonIcon: json['createButtonIcon'],
      createButtonLink: (json['createButtonLink'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}

class PageBody {
  final String styleClass;
  final TableConfig table;

  PageBody({
    required this.styleClass,
    required this.table,
  });

  factory PageBody.fromJson(Map<String, dynamic> json) {
    return PageBody(
      styleClass: json['styleClass'] ?? '',
      table: TableConfig.fromJson(json['table'] ?? {}),
    );
  }
}

class TableConfig {
  final List<TableColumn> columns;
  final String paginationType;
  final int defaultPageSize;
  final List<dynamic> pageSizeOptions;
  final String defaultSortField;
  final String defaultSortOrder;
  final String exportFilename;

  TableConfig({
    required this.columns,
    required this.paginationType,
    required this.defaultPageSize,
    required this.pageSizeOptions,
    required this.defaultSortField,
    required this.defaultSortOrder,
    required this.exportFilename,
  });

  factory TableConfig.fromJson(Map<String, dynamic> json) {
    return TableConfig(
      columns: (json['columns'] as List<dynamic>?)
          ?.map((e) => TableColumn.fromJson(e))
          .toList() ?? [],
      paginationType: json['paginationType'] ?? 'server',
      defaultPageSize: json['defaultPageSize'] ?? 20,
      pageSizeOptions: json['pageSizeOptions'] ?? [],
      defaultSortField: json['defaultSortField'] ?? '',
      defaultSortOrder: json['defaultSortOrder'] ?? 'asc',
      exportFilename: json['exportFilename'] ?? '',
    );
  }
}

class TableColumn {
  final String field;
  final String header;
  final String type;
  final String width;
  final bool isSortable;
  final bool isSearchable;
  final bool isResizable;
  final bool isVisible;
  final bool isExportable;
  final bool isFilterable;
  final bool isFrozen;
  final String? alignFrozen;
  final String? filterType;
  final String? filterMatchMode;
  final List<FilterOption>? filterOptions;

  TableColumn({
    required this.field,
    required this.header,
    required this.type,
    required this.width,
    required this.isSortable,
    required this.isSearchable,
    required this.isResizable,
    required this.isVisible,
    required this.isExportable,
    required this.isFilterable,
    required this.isFrozen,
    this.alignFrozen,
    this.filterType,
    this.filterMatchMode,
    this.filterOptions,
  });

  factory TableColumn.fromJson(Map<String, dynamic> json) {
    return TableColumn(
      field: json['field'] ?? '',
      header: json['header'] ?? '',
      type: json['type'] ?? 'string',
      width: json['width'] ?? 'auto',
      isSortable: json['isSortable'] ?? false,
      isSearchable: json['isSearchable'] ?? false,
      isResizable: json['isResizable'] ?? false,
      isVisible: json['isVisible'] ?? true,
      isExportable: json['isExportable'] ?? false,
      isFilterable: json['isFilterable'] ?? false,
      isFrozen: json['isFrozen'] ?? false,
      alignFrozen: json['alignFrozen'],
      filterType: json['filterType'],
      filterMatchMode: json['filterMatchMode'],
      filterOptions: (json['filterOptions'] as List<dynamic>?)
          ?.map((e) => FilterOption.fromJson(e))
          .toList(),
    );
  }
}

class FilterOption {
  final String label;
  final dynamic value;

  FilterOption({
    required this.label,
    required this.value,
  });

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      label: json['label'] ?? '',
      value: json['value'],
    );
  }
}
