# Generic Widget System

A reusable, type-safe widget system for creating list pages with searching, filtering, sorting, and pagination in Flutter.

## Overview

This generic widget system eliminates code duplication across similar list-based pages (Brands, Categories, Tags, Themes, Activities, etc.) by providing a common set of widgets and patterns.

## Features

- ✅ **Generic Model Interface**: Type-safe model abstraction
- ✅ **Configurable Columns**: Define table columns with custom renderers
- ✅ **Search & Filtering**: Debounced search with customizable filters
- ✅ **Sorting**: 3-state column sorting (ASC → DESC → Reset)
- ✅ **Pagination**: Page size selection and navigation
- ✅ **BLoC Pattern**: Complete state management with caching
- ✅ **Customizable UI**: Custom renderers for any column
- ✅ **Loading & Error States**: Built-in shimmer loading and error handling

## Architecture

```
GenericListScreen
  ├─ GenericSearchBar (searching + filtering)
  ├─ GenericDataTable (data display + sorting + pagination)
  └─ GenericListBloc (state management)
      └─ GenericListService (data fetching)
```

## Quick Start

### 1. Implement GenericModel in your model

```dart
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

  // Constructor, fromJson, etc...

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  @override
  dynamic getFieldValue(String fieldKey) {
    switch (fieldKey) {
      case 'id': return id;
      case 'name': return name;
      case 'isActive': return isActive ? 'Active' : 'Inactive';
      case 'createdBy': return createdBy;
      case 'createdAt': return createdAt;
      default: return null;
    }
  }
}
```

### 2. Implement GenericListService in your service

```dart
import '../widgets/generic/generic_list_bloc.dart';

class BrandService implements GenericListService<BrandModel> {
  final ApiService _apiService = GetIt.I<ApiService>();

  @override
  Future<GenericResponse<BrandModel>> getData({
    required int page,
    required int take,
    required String search,
    required String sortBy,
    required String sortOrder,
  }) async {
    // Fetch data from API
    final response = await _apiService.get('/api/brands', params: {...});

    return GenericResponse<BrandModel>(
      total: response.total,
      page: response.page,
      take: response.take,
      totalPages: response.totalPages,
      records: response.records,
    );
  }

  @override
  Future<void> deleteData(String id) async {
    await _apiService.delete('/api/brands/$id');
  }
}
```

### 3. Create your list screen using GenericListScreen

```dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../widgets/generic/index.dart';

class BrandScreen extends StatelessWidget {
  const BrandScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericListScreen<BrandModel>(
      config: GenericListScreenConfig<BrandModel>(
        title: 'Brands',
        columns: _buildColumns(),
        blocBuilder: () => GenericListBloc<BrandModel>(
          service: GetIt.I<BrandService>(),
          sortComparator: _sortComparator,
          filterPredicate: _filterPredicate,
        ),
        filterConfigs: [FilterConfig.statusFilter()],
        searchHint: 'Search brands...',
        emptyIcon: Icons.branding_watermark_outlined,
        emptyMessage: 'No brands found',
        showCreateButton: true,
        showSerialNumber: true,
      ),
    );
  }

  List<GenericColumnConfig<BrandModel>> _buildColumns() {
    return [
      // Simple text column
      GenericColumnConfig<BrandModel>(
        label: 'Brand Name',
        fieldKey: 'name',
        sortable: true,
      ),

      // Status badge (built-in helper)
      GenericColumnConfig.statusBadge<BrandModel>(
        getStatus: (brand) => brand.isActive ? 'Active' : 'Inactive',
        isActive: (brand) => brand.isActive,
      ),

      // Custom renderer
      GenericColumnConfig<BrandModel>(
        label: 'Brand Name',
        fieldKey: 'name',
        sortable: true,
        customRenderer: (brand, index) {
          return Row(
            children: [
              CircleAvatar(child: Text(brand.name[0])),
              SizedBox(width: 8),
              Text(brand.name),
            ],
          );
        },
      ),

      GenericColumnConfig<BrandModel>(
        label: 'Created By',
        fieldKey: 'createdBy',
        sortable: true,
      ),

      GenericColumnConfig<BrandModel>(
        label: 'Created Date',
        fieldKey: 'createdAt',
        sortable: true,
      ),
    ];
  }

  int _sortComparator(
    BrandModel a,
    BrandModel b,
    String sortBy,
    String sortOrder,
  ) {
    int comparison = 0;
    switch (sortBy) {
      case 'name':
        comparison = a.name.compareTo(b.name);
        break;
      case 'createdAt':
        comparison = _parseDate(a.createdAt).compareTo(_parseDate(b.createdAt));
        break;
      default:
        comparison = 0;
    }
    return sortOrder == 'asc' ? comparison : -comparison;
  }

  bool _filterPredicate(BrandModel brand, Map<String, dynamic> filters) {
    if (filters.containsKey('status')) {
      final status = filters['status'];
      if (status == 'active' && !brand.isActive) return false;
      if (status == 'inactive' && brand.isActive) return false;
    }
    return true;
  }

  DateTime _parseDate(String dateStr) {
    // Parse your date format
    return DateTime.now();
  }
}
```

## Configuration Options

### GenericListScreenConfig

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `title` | String | Page title | Required |
| `columns` | List<GenericColumnConfig> | Column definitions | Required |
| `blocBuilder` | Function | BLoC factory | Required |
| `filterConfigs` | List<FilterConfig> | Filter options | `[]` |
| `searchHint` | String | Search placeholder | `'Search...'` |
| `emptyIcon` | IconData | Empty state icon | `Icons.inbox_outlined` |
| `emptyMessage` | String | Empty state message | `'No data found'` |
| `showCreateButton` | bool | Show add button | `true` |
| `createRoute` | String? | Route for create page | `null` |
| `onCreatePressed` | VoidCallback? | Custom create handler | `null` |
| `showSerialNumber` | bool | Show SR column | `true` |
| `showTotalCount` | bool | Show total count badge | `false` |
| `enableEdit` | bool | Enable edit action | `false` |
| `enableDelete` | bool | Enable delete action | `false` |

### GenericColumnConfig

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `label` | String | Column header | Required |
| `fieldKey` | String | Field name for sorting | Required |
| `sortable` | bool | Enable sorting | `false` |
| `customRenderer` | Function? | Custom cell renderer | `null` |
| `width` | double? | Column width | `null` |
| `visible` | bool | Show/hide column | `true` |

### FilterConfig

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `label` | String | Filter label | Required |
| `key` | String | Filter key | Required |
| `options` | List<FilterOption> | Filter options | Required |

**Built-in Helper:**
```dart
FilterConfig.statusFilter() // Creates Active/Inactive filter
```

## Examples

### Example 1: Simple Text Columns

```dart
GenericColumnConfig<BrandModel>(
  label: 'Brand Name',
  fieldKey: 'name',
  sortable: true,
)
```

### Example 2: Status Badge

```dart
GenericColumnConfig.statusBadge<BrandModel>(
  getStatus: (brand) => brand.isActive ? 'Active' : 'Inactive',
  isActive: (brand) => brand.isActive,
)
```

### Example 3: Custom Renderer with Avatar

```dart
GenericColumnConfig<BrandModel>(
  label: 'Brand',
  fieldKey: 'name',
  sortable: true,
  customRenderer: (brand, index) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              brand.name[0].toUpperCase(),
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Text(brand.name),
      ],
    );
  },
)
```

### Example 4: Expandable Description

```dart
class _MyScreenState extends State<MyScreen> {
  final Map<int, bool> _expandedRows = {};

  GenericColumnConfig<CategoryModel> _descriptionColumn() {
    return GenericColumnConfig<CategoryModel>(
      label: 'Description',
      fieldKey: 'description',
      sortable: false,
      customRenderer: (category, index) {
        final isExpanded = _expandedRows[index] ?? false;
        final description = category.description;

        return GestureDetector(
          onTap: () {
            setState(() {
              _expandedRows[index] = !isExpanded;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isExpanded || description.length <= 50
                    ? description
                    : '${description.substring(0, 50)}...',
              ),
              if (description.length > 50)
                Text(
                  isExpanded ? 'Show less' : 'Show more',
                  style: TextStyle(color: Colors.blue),
                ),
            ],
          ),
        );
      },
    );
  }
}
```

### Example 5: Custom Filters

```dart
FilterConfig(
  label: 'Category',
  key: 'category',
  options: [
    FilterOption(label: 'All', value: 'all'),
    FilterOption(label: 'Electronics', value: 'electronics'),
    FilterOption(label: 'Clothing', value: 'clothing'),
  ],
)
```

## Advanced Usage

### Custom Sort Comparator

```dart
int _customSortComparator(
  MyModel a,
  MyModel b,
  String sortBy,
  String sortOrder,
) {
  int comparison = 0;

  switch (sortBy) {
    case 'name':
      comparison = a.name.compareTo(b.name);
      break;
    case 'price':
      comparison = a.price.compareTo(b.price);
      break;
    case 'date':
      comparison = DateTime.parse(a.date).compareTo(DateTime.parse(b.date));
      break;
    default:
      comparison = 0;
  }

  return sortOrder == 'asc' ? comparison : -comparison;
}
```

### Custom Filter Predicate

```dart
bool _customFilterPredicate(MyModel model, Map<String, dynamic> filters) {
  // Status filter
  if (filters.containsKey('status')) {
    final status = filters['status'];
    if (status == 'active' && !model.isActive) return false;
    if (status == 'inactive' && model.isActive) return false;
  }

  // Category filter
  if (filters.containsKey('category')) {
    final category = filters['category'];
    if (category != 'all' && model.category != category) return false;
  }

  // Price range filter
  if (filters.containsKey('priceRange')) {
    final range = filters['priceRange'];
    if (range == 'low' && model.price > 100) return false;
    if (range == 'high' && model.price <= 100) return false;
  }

  return true;
}
```

## Migration Guide

To migrate existing pages to use the generic widget system:

1. Update your model to implement `GenericModel`
2. Update your service to implement `GenericListService`
3. Replace your screen widget with `GenericListScreen`
4. Define your columns using `GenericColumnConfig`
5. Provide sort comparator and filter predicate functions

**Before:**
```dart
// 5 separate files (screen, bloc, events, states, widgets)
// ~800 lines of code
```

**After:**
```dart
// 1 file
// ~150 lines of code
```

## Benefits

- **90% Code Reduction**: From ~800 lines to ~150 lines per page
- **Consistency**: All list pages work the same way
- **Maintainability**: Fix bugs once, applies everywhere
- **Type Safety**: Compile-time checking for all types
- **Flexibility**: Custom renderers for any special cases
- **Performance**: Client-side caching and filtering

## Files

- `generic_model.dart` - Base model interface
- `generic_column_config.dart` - Column configuration
- `generic_search_bar.dart` - Search and filter widget
- `generic_data_table.dart` - Data table with pagination
- `generic_list_bloc.dart` - BLoC with events, states, service interface
- `generic_list_screen.dart` - Complete screen widget
- `index.dart` - Export all widgets

## Examples in Codebase

- `brand_screen_new.dart` - Brands page using generic widgets
- `category_screen_new.dart` - Categories page with expandable description

## License

Internal use only.
