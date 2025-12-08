import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../widgets/generic/index.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final Map<int, bool> _expandedRows = {};

  @override
  Widget build(BuildContext context) {
    return GenericListScreen<CategoryModel>(
      config: GenericListScreenConfig<CategoryModel>(
        title: 'Categories',
        columns: _buildColumns(),
        blocBuilder: () => GenericListBloc<CategoryModel>(
          service: GetIt.I<CategoryService>(),
          sortComparator: _categorySortComparator,
          filterPredicate: _categoryFilterPredicate,
        ),
        filterConfigs: [FilterConfig.statusFilter()],
        searchHint: 'Search categories...',
        emptyIcon: Icons.category_outlined,
        emptyMessage: 'No categories found',
        showCreateButton: true,
        showSerialNumber: true,
        showTotalCount: true,
        enableEdit: false,
        enableDelete: false,
      ),
    );
  }

  /// Define columns for category table
  List<GenericColumnConfig<CategoryModel>> _buildColumns() {
    return [
      // Category Name
      GenericColumnConfig<CategoryModel>(
        label: 'Category Name',
        fieldKey: 'name',
        sortable: true,
        customRenderer: (category, index) {
          return Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          );
        },
      ),

      // Description (expandable)
      GenericColumnConfig<CategoryModel>(
        label: 'Description',
        fieldKey: 'description',
        sortable: false,
        customRenderer: (category, index) {
          final isExpanded = _expandedRows[index] ?? false;
          final description = category.description;

          if (description.isEmpty) {
            return const Text(
              '-',
              style: TextStyle(color: AppColors.grey),
            );
          }

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
                  style: const TextStyle(fontSize: 14),
                ),
                if (description.length > 50)
                  Text(
                    isExpanded ? 'Show less' : 'Show more',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          );
        },
      ),

      // Status badge
      GenericColumnConfig.statusBadge<CategoryModel>(
        getStatus: (category) => category.isActive ? 'Active' : 'Inactive',
        isActive: (category) => category.isActive,
      ),

      // Created By
      GenericColumnConfig<CategoryModel>(
        label: 'Created By',
        fieldKey: 'createdBy',
        sortable: true,
      ),

      // Created Date
      GenericColumnConfig<CategoryModel>(
        label: 'Created Date',
        fieldKey: 'createdAt',
        sortable: true,
      ),
    ];
  }

  /// Sort comparator for categories
  int _categorySortComparator(
    CategoryModel a,
    CategoryModel b,
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
      case 'isActive':
        comparison = a.isActive == b.isActive ? 0 : (a.isActive ? 1 : -1);
        break;
      case 'createdBy':
        comparison = a.createdBy.compareTo(b.createdBy);
        break;
      default:
        comparison = 0;
    }

    return sortOrder == 'asc' ? comparison : -comparison;
  }

  /// Filter predicate for categories
  bool _categoryFilterPredicate(
    CategoryModel category,
    Map<String, dynamic> filters,
  ) {
    // Apply status filter
    if (filters.containsKey('status')) {
      final statusFilter = filters['status'];
      if (statusFilter == 'active' && !category.isActive) return false;
      if (statusFilter == 'inactive' && category.isActive) return false;
    }

    return true;
  }

  /// Parse date string in format "DD-MM-YYYY"
  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
      }
    } catch (e) {
      // Return current date if parsing fails
    }
    return DateTime.now();
  }
}
